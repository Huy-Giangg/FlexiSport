import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // CORS preflight handling
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ""
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? "" // Bypass RLS to update payment status
    const client = createClient(supabaseUrl, supabaseServiceKey)

    // 1. Webhook Authentication
    const webhookToken = Deno.env.get('WEBHOOK_SECRET_TOKEN') // Secure Token set on SePay/Casso/PayOS settings
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
    const receivedToken = req.headers.get('x-api-key') || 
                          req.headers.get('apikey') || 
                          req.headers.get('Authorization')?.replace('Bearer ', '')?.replace('Apikey ', '')

    const isAuthorized = !webhookToken || 
                         (receivedToken && (receivedToken === webhookToken || receivedToken === anonKey))

    if (!isAuthorized) {
      console.error("Webhook authentication failed. Tokens do not match.");
      return new Response(JSON.stringify({ error: "Unauthorized" }), { 
        status: 401, 
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      })
    }

    const payload = await req.json()
    console.log("Received VietQR Webhook payload:", JSON.stringify(payload))

    // 2. Extract transaction details
    let paymentRef = ""
    let amount = 0
    let transactionCode = ""

    // Search for FLEXI reference pattern in description, content, or code first
    const fullText = `${payload.description || ''} ${payload.content || ''} ${payload.code || ''}`
    const flexiMatch = fullText.toUpperCase().match(/FLEXI[A-Z0-9]+/)

    // Format A: SePay (direct transaction content matching)
    if (payload.transferAmount !== undefined || payload.code || payload.content || payload.description) {
      paymentRef = flexiMatch ? flexiMatch[0] : (payload.code ? payload.code.trim().toUpperCase() : "")
      amount = Number(payload.transferAmount ?? payload.amount ?? 0)
      transactionCode = payload.referenceCode || String(payload.id || "")
    } 
    // Format B: Casso
    else if (payload.data && Array.isArray(payload.data)) {
      const tx = payload.data[0]
      if (tx) {
        const match = tx.description.toUpperCase().match(/FLEXI[A-Z0-9]+/)
        paymentRef = match ? match[0] : ""
        amount = Number(tx.amount)
        transactionCode = tx.tid
      }
    } 
    // Format C: PayOS
    else if (payload.orderCode) {
      paymentRef = String(payload.orderCode)
      amount = Number(payload.amount)
      transactionCode = payload.reference
    }

    if (!paymentRef) {
      console.warn("Could not extract payment reference from the payload.");
      return new Response(JSON.stringify({ error: "Missing payment reference" }), { 
        status: 400, 
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      })
    }

    // Clean payment reference
    const match = paymentRef.match(/FLEXI[A-Z0-9]+/i)
    if (match) {
      paymentRef = match[0].toUpperCase()
    }

    console.log(`Processing txn: Reference=${paymentRef}, Amount=${amount}, TxnCode=${transactionCode}`)

    // 3. Find transaction in payments table (state: PENDING) - Query directly without join
    const { data: paymentRecord, error: fetchError } = await client
      .from('payments')
      .select('id, amount, status, booking_id')
      .eq('payment_reference', paymentRef)
      .maybeSingle()

    // 3b. If not found in payments, check event_bookings table (for event ticket purchases)
    if (!paymentRecord) {
      console.log(`Reference ${paymentRef} not in payments, searching in event_bookings...`);
      const { data: eventRecord, error: evError } = await client
        .from('event_bookings')
        .select('id, total_amount, status, user_id, note')
        .ilike('note', `%${paymentRef}%`)
        .maybeSingle()

      if (!eventRecord) {
        console.error(`Transaction not found in payments or event_bookings for reference: ${paymentRef}`);
        const { data: allPayments } = await client.from('payments').select('payment_reference');
        return new Response(JSON.stringify({ 
          error: "Payment record not found",
          details: "No payment or event booking matched the reference.",
          available_references: allPayments ? allPayments.map(p => p.payment_reference) : []
        }), { 
          status: 404, 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        })
      }

      // If event booking has already succeeded (Idempotency)
      if (eventRecord.status === 'completed') {
        console.log(`Event booking ${eventRecord.id} with ${paymentRef} was already processed successfully.`);
        return new Response(JSON.stringify({ success: true, message: "Already processed" }), { 
          status: 200, 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        })
      }

      // Validate amount for event booking
      const expectedAmount = Number(eventRecord.total_amount)
      if (amount < expectedAmount) {
        console.warn(`Transferred amount (${amount}) is less than expected event booking amount (${expectedAmount}).`);
        return new Response(JSON.stringify({ error: "Amount mismatch" }), { 
          status: 400, 
          headers: { ...corsHeaders, "Content-Type": "application/json" } 
        })
      }

      // Update event booking to completed
      const { error: updateEvError } = await client
        .from('event_bookings')
        .update({ 
          status: 'completed',
        })
        .eq('id', eventRecord.id)

      if (updateEvError) {
        throw new Error(`Failed to update event_bookings: ${updateEvError.message}`)
      }

      console.log(`Event booking ${eventRecord.id} confirmed successfully with reference ${paymentRef}.`);
      return new Response(JSON.stringify({ 
        success: true, 
        message: "Event booking payment processed successfully",
        booking_id: eventRecord.id,
        reference: paymentRef
      }), { 
        status: 200, 
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      })
    }

    // If transaction has already succeeded (Idempotency)
    if (paymentRecord.status === 'SUCCESS') {
      console.log(`Transaction ${paymentRef} was already processed successfully.`);
      return new Response(JSON.stringify({ success: true, message: "Already processed" }), { 
        status: 200, 
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      })
    }

    // 4. Validate amount
    const expectedAmount = Number(paymentRecord.amount)
    if (amount < expectedAmount) {
      console.warn(`Transferred amount (${amount}) is less than expected booking amount (${expectedAmount}).`);
      return new Response(JSON.stringify({ error: "Amount mismatch" }), { 
        status: 400, 
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      })
    }

    // 5. Update Database with slot safety verification (Payment -> SUCCESS, Booking -> COMPLETED)
    const bookingId = paymentRecord.booking_id

    // Query bookings table directly to fetch status & user_id
    const { data: bookingRecord } = await client
      .from('bookings')
      .select('user_id, status, customer_name, customer_phone')
      .eq('id', bookingId)
      .single()

    const userId = bookingRecord?.user_id
    const isCancelled = bookingRecord?.status === 'cancelled'

    // Fetch slots associated with this booking
    const { data: bookedSlots } = await client
      .from('booking_slots')
      .select('id, court_id, booking_date, slot_index, is_active')
      .eq('booking_id', bookingId)

    // Check if any slot has been taken by another active booking (stolen slot protection)
    let isSlotStolen = false
    if (bookedSlots && bookedSlots.length > 0) {
      for (const slot of bookedSlots) {
        const { data: conflict } = await client
          .from('booking_slots')
          .select('id, bookings!inner(status)')
          .eq('court_id', slot.court_id)
          .eq('booking_date', slot.booking_date)
          .eq('slot_index', slot.slot_index)
          .neq('booking_id', bookingId)
          .eq('is_active', true)
          .in('bookings.status', ['completed', 'confirmed', 'pending_payment'])
          .maybeSingle()

        if (conflict) {
          isSlotStolen = true
          break
        }
      }
    }

    if (isSlotStolen) {
      console.warn(`CRITICAL: Slot for booking ${bookingId} was taken while customer was paying! Reference: ${paymentRef}`)
      
      // Update payment record as overdue and flag for immediate refund
      await client
        .from('payments')
        .update({
          status: 'REFUND_REQUIRED',
          transaction_code: transactionCode,
          raw_callback_data: payload,
          paid_at: new Date().toISOString()
        })
        .eq('id', paymentRecord.id)

      await client
        .from('bookings')
        .update({
          status: 'cancelled',
          note: `Đã nhận chuyển khoản ${amount}đ (${paymentRef}) nhưng khung giờ đã bị người khác đặt trước do quá hạn giữ chỗ. CẦN HOÀN TIỀN CHO KHÁCH.`
        })
        .eq('id', bookingId)

      // Notify customer and owner
      try {
        if (userId) {
          await client.from('notifications').insert({
            user_id: userId,
            title: 'Khung giờ đặt sân đã bị trùng',
            body: `Giao dịch ${paymentRef} thành công nhưng khung giờ đã bị người khác đặt trước. Hệ thống/chủ sân sẽ liên hệ hoàn tiền cho bạn.`,
            type: 'booking_conflict'
          })
        }
      } catch (_) {}

      return new Response(JSON.stringify({ 
        success: false, 
        status: "REFUND_REQUIRED",
        message: "Payment received but slot was already booked by another user. Marked for refund." 
      }), { 
        status: 200, 
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      })
    }

    // Update payment to SUCCESS
    const { error: updatePaymentError } = await client
      .from('payments')
      .update({
        status: 'SUCCESS',
        transaction_code: transactionCode,
        raw_callback_data: payload,
        paid_at: new Date().toISOString()
      })
      .eq('id', paymentRecord.id)

    if (updatePaymentError) {
      throw new Error(`Failed to update payments: ${updatePaymentError.message}`)
    }

    // Re-activate slots if they were marked inactive on cancel
    if (bookedSlots && bookedSlots.length > 0) {
      await client
        .from('booking_slots')
        .update({ is_active: true })
        .eq('booking_id', bookingId)
    }

    // Update booking status to completed
    const { error: updateBookingError } = await client
      .from('bookings')
      .update({ 
        status: 'completed'
      })
      .eq('id', bookingId)

    if (updateBookingError) {
      throw new Error(`Failed to update bookings: ${updateBookingError.message}`)
    }

    // Release temporary locks in court_locks for these specific slots
    if (bookedSlots && bookedSlots.length > 0) {
      for (const slot of bookedSlots) {
        await client
          .from('court_locks')
          .delete()
          .eq('court_id', slot.court_id)
          .eq('booking_date', slot.booking_date)
          .eq('slot_index', slot.slot_index)
      }
    }
    if (userId) {
      await client
        .from('court_locks')
        .delete()
        .eq('user_id', userId)
    }

    console.log(`Transaction ${paymentRef} processed successfully. Booking ${bookingId} confirmed.`);

    return new Response(JSON.stringify({ success: true, message: "Payment processed successfully" }), { 
      status: 200, 
      headers: { ...corsHeaders, "Content-Type": "application/json" } 
    })

  } catch (err) {
    console.error("System error during webhook execution:", err)
    return new Response(JSON.stringify({ error: err.message }), { 
      status: 500, 
      headers: { ...corsHeaders, "Content-Type": "application/json" } 
    })
  }
})
