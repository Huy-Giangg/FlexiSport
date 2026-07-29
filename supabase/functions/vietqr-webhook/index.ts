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
    const receivedToken = req.headers.get('x-api-key') || req.headers.get('Authorization')?.replace('Apikey ', '')

    if (webhookToken && receivedToken !== webhookToken) {
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
      .single()

    // Fetch all available references for debugging
    const { data: allPayments } = await client.from('payments').select('payment_reference');

    if (fetchError || !paymentRecord) {
      console.error(`Transaction not found for reference: ${paymentRef}`, fetchError);
      return new Response(JSON.stringify({ 
        error: "Payment record not found",
        details: fetchError ? fetchError.message : "No payment record matched the reference.",
        available_references: allPayments ? allPayments.map(p => p.payment_reference) : []
      }), { 
        status: 404, 
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

    // 5. Update Database within transaction (Payment -> SUCCESS, Booking -> CONFIRMED, Clear court_locks)
    const bookingId = paymentRecord.booking_id

    // Query bookings table directly to fetch user_id
    const { data: bookingRecord } = await client
      .from('bookings')
      .select('user_id')
      .eq('id', bookingId)
      .single()

    const userId = bookingRecord?.user_id

    // Update payment
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

    // Update booking status to completed (lowercase, expected by the app)
    const { error: updateBookingError } = await client
      .from('bookings')
      .update({ status: 'completed' })
      .eq('id', bookingId)

    if (updateBookingError) {
      throw new Error(`Failed to update bookings: ${updateBookingError.message}`)
    }

    // Release temporary locks in court_locks
    if (userId) {
      const { error: deleteLocksError } = await client
        .from('court_locks')
        .delete()
        .eq('user_id', userId)
      
      if (deleteLocksError) {
        console.warn(`Warning: Failed to clear court_locks: ${deleteLocksError.message}`)
      }
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
