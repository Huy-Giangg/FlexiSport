import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flexisport_app/features/owner/court_management/domain/entities/owner_venue_entity.dart';
import 'package:flexisport_app/features/owner/court_management/presentation/providers/owner_court_provider.dart';

class BankSettingsDialog extends StatefulWidget {
  final OwnerVenueEntity venue;
  final OwnerCourtProvider provider;

  const BankSettingsDialog({
    super.key,
    required this.venue,
    required this.provider,
  });

  static void show(BuildContext context, OwnerVenueEntity venue, OwnerCourtProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BankSettingsDialog(venue: venue, provider: provider),
    );
  }

  @override
  State<BankSettingsDialog> createState() => _BankSettingsDialogState();
}

class _BankSettingsDialogState extends State<BankSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _accountNumberController;
  late String _selectedBank;
  bool _isSaving = false;

  final List<String> _popularBanks = [
    'Vietcombank (VCB)',
    'MB Bank (Ngân hàng Quân đội)',
    'Techcombank (TCB)',
    'BIDV (Ngân hàng Đầu tư)',
    'VietinBank (CTG)',
    'VPBank (VPB)',
    'ACB (Á Châu)',
    'TPBank (Tiên Phong)',
    'Sacombank (STB)',
    'Agribank (Nông nghiệp)',
    'Khác / Ví điện tử',
  ];

  @override
  void initState() {
    super.initState();
    _accountNumberController = TextEditingController(text: widget.venue.accountNumber ?? '');
    _selectedBank = widget.venue.bankName != null && _popularBanks.contains(widget.venue.bankName)
        ? widget.venue.bankName!
        : _popularBanks.first;
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final success = await widget.provider.updateVenueInfo(
      name: widget.venue.name,
      address: widget.venue.address,
      openTime: widget.venue.openTime,
      closeTime: widget.venue.closeTime,
      sportsType: widget.venue.sportsType,
      bankName: _selectedBank,
      accountNumber: _accountNumberController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? "Đã lưu tài khoản ngân hàng thành công!" : "Lưu tài khoản thất bại",
            style: GoogleFonts.lexend(),
          ),
          backgroundColor: success ? AppColors.primary : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: Color(0xFF059669), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Tài khoản nhận tiền cọc",
                      style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Thông tin này sẽ được hiển thị khi khách hàng quét mã QR chuyển khoản tiền cọc / thanh toán sân.",
                style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              Text("Ngân hàng thụ hưởng *", style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedBank,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.account_balance_outlined, color: AppColors.primary),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                style: GoogleFonts.lexend(fontSize: 13, color: AppColors.onBackground),
                items: _popularBanks.map((b) {
                  return DropdownMenuItem(value: b, child: Text(b, style: GoogleFonts.lexend(fontSize: 13)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedBank = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              Text("Số tài khoản *", style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "Ví dụ: 19036888888888",
                  prefixIcon: const Icon(Icons.credit_card_rounded, color: AppColors.primary),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? "Vui lòng nhập số tài khoản" : null,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("Lưu tài khoản ngân hàng", style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
