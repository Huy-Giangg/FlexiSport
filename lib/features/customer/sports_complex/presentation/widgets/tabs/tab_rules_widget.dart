import 'package:flexisport_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TabRulesWidget extends StatelessWidget {
  const TabRulesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. Quy định đặt sân
        _buildSectionHeader(
          icon: Icons.bookmark_added_outlined,
          title: 'Quy định đặt sân',
        ),
        const SizedBox(height: 8),
        _buildContentCard(
          children: [
            _buildBulletItem(
              title: 'Giữ chỗ trực tuyến',
              content:
                  'Khách hàng chọn sân và khung giờ trực tiếp trên ứng dụng. Khung giờ được khóa tạm thời trong 10 phút để quý khách hoàn tất thanh toán.',
            ),
            const SizedBox(height: 8),
            _buildBulletItem(
              title: 'Thanh toán tự động',
              content:
                  'Thanh toán 100% qua chuyển khoản ngân hàng tự động (VietQR). Hệ thống sẽ tự động xác nhận lịch đặt ngay khi nhận được thanh toán.',
            ),
            const SizedBox(height: 8),
            _buildBulletItem(
              title: 'Nhận sân thi đấu',
              content:
                  'Quý khách xuất trình mã đặt sân (hoặc số điện thoại đã đặt) tại quầy lễ tân để nhận sân đúng giờ.',
            ),
          ],
        ),

        const SizedBox(height: 18),

        // 2. Quy định hủy sân & chính sách hoàn tiền
        _buildSectionHeader(
          icon: Icons.assignment_return_outlined,
          title: 'Quy định hủy sân & hoàn tiền',
        ),
        const SizedBox(height: 8),
        _buildRefundPolicyCard(),

        const SizedBox(height: 18),

        // 3. Quy định đổi / dời lịch
        _buildSectionHeader(
          icon: Icons.update_rounded,
          title: 'Quy định dời lịch chơi',
        ),
        const SizedBox(height: 8),
        _buildContentCard(
          children: [
            _buildBulletItem(
              title: 'Hỗ trợ dời lịch',
              content:
                  'Quý khách có nhu cầu dời giờ hoặc đổi ngày vui lòng liên hệ trực tiếp hotline ban quản lý sân trước giờ bắt đầu để được kiểm tra và hỗ trợ theo tình trạng sân trống thực tế.',
            ),
          ],
        ),

        const SizedBox(height: 18),

        // 4. Quy định trang phục
        _buildSectionHeader(
          icon: Icons.sports_tennis_outlined,
          title: 'Quy định trang phục & dụng cụ',
        ),
        const SizedBox(height: 8),
        _buildContentCard(
          children: [
            _buildBulletItem(
              title: 'Giày chuyên dụng',
              content:
                  'Sử dụng giày thể thao đế bằng, đế cao su chuyên dụng (cầu lông, tennis, pickleball, bóng đá sân cỏ). Nghiêm cấm đi giày cao gót, giày da, giày đế đinh kim loại gây hư hại mặt sân.',
            ),
          ],
        ),

        const SizedBox(height: 18),

        // 5. Giữ gìn vệ sinh & trật tự chung
        _buildSectionHeader(
          icon: Icons.cleaning_services_outlined,
          title: 'Vệ sinh & an ninh chung',
        ),
        const SizedBox(height: 8),
        _buildContentCard(
          children: [
            _buildBulletItem(
              title: 'Vệ sinh',
              content:
                  'Bỏ rác đúng nơi quy định. Không mang đồ ăn có mùi, thức uống có cồn, kẹo cao su vào bên trong khu vực mặt sân thi đấu.',
            ),
            const SizedBox(height: 8),
            _buildBulletItem(
              title: 'An ninh & an toàn',
              content:
                  'Tự bảo quản tư trang cá nhân có giá trị. Nghiêm cấm hút thuốc lá, đánh bạc, gây gổ hoặc các hành vi vi phạm pháp luật trong khuôn viên cơ sở.',
            ),
          ],
        ),

        const SizedBox(height: 18),

        // 6. Thời gian ra vào sân
        _buildSectionHeader(
          icon: Icons.access_time_rounded,
          title: 'Thời gian nhận & trả sân',
        ),
        const SizedBox(height: 8),
        _buildContentCard(
          children: [
            _buildBulletItem(
              title: 'Đến trước giờ chơi',
              content:
                  'Vui lòng có mặt trước giờ đặt 5 - 10 phút để khởi động và hoàn tất thủ tục nhận sân.',
            ),
            const SizedBox(height: 8),
            _buildBulletItem(
              title: 'Bàn giao sân đúng giờ',
              content:
                  'Kết thúc ca chơi đúng giờ quy định để không làm ảnh hưởng đến lượt thi đấu của khách hàng tiếp theo.',
            ),
          ],
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildBulletItem({required String title, required String content}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.secondary,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
                  ),
                ),
                TextSpan(text: content),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefundPolicyCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chính sách hoàn tiền theo thời gian hủy:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 10),
          _buildRefundTierRow(
            label: 'Hủy trước ≥ 24 giờ / Đơn chờ duyệt',
            refundRate: 'Hoàn 100%',
            badgeColor: const Color(0xFF16A34A),
            description:
                'Hoàn lại 100% số tiền đã thanh toán vào tài khoản ngân hàng của bạn.',
          ),
          const Divider(height: 16, thickness: 0.8),
          _buildRefundTierRow(
            label: 'Hủy từ 2h - 24h trước giờ chơi',
            refundRate: 'Hoàn 50%',
            badgeColor: const Color(0xFFEA580C),
            description:
                'Khấu trừ 50% chi phí hỗ trợ giữ sân và vận hành cho cơ sở thể thao.',
          ),
          const Divider(height: 16, thickness: 0.8),
          _buildRefundTierRow(
            label: 'Hủy sát giờ chơi (< 2 giờ)',
            refundRate: 'Không hoàn (0%)',
            badgeColor: const Color(0xFFDC2626),
            description:
                'Hệ thống tự động khóa hủy trực tuyến. Vui lòng liên hệ hotline cơ sở nếu có sự cố khẩn cấp.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Thời gian hoàn tiền: Tiền hoàn sẽ được chuyển về tài khoản ngân hàng thụ hưởng của quý khách trong vòng 1 - 3 ngày làm việc.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.blue.shade900,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundTierRow({
    required String label,
    required String refundRate,
    required Color badgeColor,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                refundRate,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

