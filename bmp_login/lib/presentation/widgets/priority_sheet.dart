import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bmp_login/core/utils/jwt_storage.dart';

class PrioritySheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.priority_high, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Priority Sheet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildFilterOption(
              context,
              icon: Icons.hourglass_empty,
              title: 'Pending Loans',
              color: Colors.orange,
              status: 'PENDING',
            ),
            _buildFilterOption(
              context,
              icon: Icons.check_circle,
              title: 'Approved Loans',
              color: Colors.green,
              status: 'APPROVED',
            ),
            _buildFilterOption(
              context,
              icon: Icons.cancel,
              title: 'Rejected Loans',
              color: Colors.red,
              status: 'NOT_ELIGIBLE',
            ),
            _buildFilterOption(
              context,
              icon: Icons.list,
              title: 'All Loan Requests',
              color: Colors.blue,
              status: null,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildFilterOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    String? status,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        Navigator.pop(context);
        final username = await JwtStorage.getUsername();
        
        if (status == null) {
          // All loan requests
          Get.toNamed('/loan-request-list', arguments: {
            'isAdmin': false,
            'title': 'All Loan Requests',
          });
        } else {
          // Filtered by status
          Get.toNamed('/loan-request-list', arguments: {
            'isAdmin': false,
            'status': status,
            'username': username,
            'title': title,
          });
        }
      },
    );
  }
}