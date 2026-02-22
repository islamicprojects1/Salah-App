import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/features/family/controller/family_controller.dart';
import 'package:salah/features/family/data/models/group_model.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CREATE GROUP SCREEN
// المسار: lib/features/family/presentation/screens/create_group_screen.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  GroupType _type = GroupType.family;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final ok = await Get.find<FamilyController>().createGroup(
      type: _type,
      name: _nameCtrl.text.trim(),
    );

    if (ok) {
      Get.back();
    } else {
      Get.rawSnackbar(
        message: 'create_group_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        messageText: Text(
          'create_group_error'.tr,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<FamilyController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('create_group'.tr),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── نوع المجموعة ──────────────────────────────────────
            Text(
              'group_type'.tr,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _TypeSelector(
              selected: _type,
              onChanged: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: 28),

            // ── الاسم ─────────────────────────────────────────────
            Text(
              'group_name'.tr,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              maxLength: 50,
              decoration: InputDecoration(
                hintText: 'group_name_hint'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 4),
            Text(
              'group_name_optional'.tr,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 40),

            // ── زر الإنشاء ────────────────────────────────────────
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: ctrl.isActionLoading.value ? null : _create,
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
                          'create'.tr,
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

// ── اختيار نوع المجموعة ────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final GroupType selected;
  final ValueChanged<GroupType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = [
      (GroupType.family, '👨‍👩‍👧‍👦', 'family_type', 'family_type_desc'),
      (GroupType.guided, '📖', 'guided_type', 'guided_type_desc'),
      (GroupType.friends, '🤝', 'friends_type', 'friends_type_desc'),
    ];

    return Column(
      children: items.map((item) {
        final (type, emoji, labelKey, descKey) = item;
        final isSelected = selected == type;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1A6B4A).withOpacity(0.08)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1A6B4A)
                    : Colors.grey.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labelKey.tr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? const Color(0xFF1A6B4A) : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        descKey.tr,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF1A6B4A),
                    size: 22,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
