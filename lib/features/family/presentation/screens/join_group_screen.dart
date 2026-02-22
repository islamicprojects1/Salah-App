import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/features/family/controller/family_controller.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// JOIN GROUP SCREEN
// المسار: lib/features/family/presentation/screens/join_group_screen.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _codeCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'code_required'.tr);
      return;
    }
    if (code.length != 8) {
      setState(() => _error = 'code_invalid_length'.tr);
      return;
    }
    setState(() => _error = null);

    final result = await Get.find<FamilyController>().joinByCode(code);

    switch (result) {
      case 'success':
      case 'already_member':
        Get.back();
        break;
      case 'not_found':
        setState(() => _error = 'code_not_found'.tr);
        break;
      case 'blocked':
        setState(() => _error = 'you_are_blocked'.tr);
        break;
      case 'offline':
        setState(() => _error = 'no_internet'.tr);
        break;
      default:
        setState(() => _error = 'join_error_generic'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<FamilyController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('join_group'.tr),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── أيقونة ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A6B4A).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group_add_rounded,
                size: 48,
                color: Color(0xFF1A6B4A),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'enter_invite_code'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'enter_invite_code_sub'.tr,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),

            // ── حقل الكود ────────────────────────────────────────
            TextField(
              controller: _codeCtrl,
              maxLength: 8,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
              ),
              decoration: InputDecoration(
                hintText: 'XXXXXXXX',
                hintStyle: TextStyle(
                  fontSize: 24,
                  letterSpacing: 6,
                  color: Colors.grey[300],
                  fontWeight: FontWeight.w400,
                ),
                counterText: '',
                errorText: _error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF1A6B4A),
                    width: 2,
                  ),
                ),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: 28),

            // ── زر الانضمام ───────────────────────────────────────
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: ctrl.isActionLoading.value ? null : _join,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6B4A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: ctrl.isActionLoading.value
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'join'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
