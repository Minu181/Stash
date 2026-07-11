import 'dart:io';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';

import 'package:stash/data/database.dart';
import 'package:stash/features/goals/goal_options.dart';
import 'package:stash/theme/app_theme.dart';
import 'package:stash/widgets/goal_image.dart';

class GoalFormPage extends ConsumerStatefulWidget {
  final Goal? goal;
  const GoalFormPage({super.key, this.goal});

  @override
  ConsumerState<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends ConsumerState<GoalFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  Color _selectedColor = GoalOptions.palette.first;
  int _selectedIcon = GoalOptions.icons.first.codePoint;
  DateTime? _deadline;
  String? _selectedImageUrl;
  bool _isPickingImage = false;
  bool _showHexInput = false;
  final _hexController = TextEditingController();
  late final bool _isEdit;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.goal != null;
    if (_isEdit) {
      final g = widget.goal!;
      _nameController.text = g.name;
      _targetController.text = g.targetAmount.toString();
      _selectedColor = Color(g.color);
      _selectedIcon = g.icon;
      _deadline = g.deadline;
      _selectedImageUrl = g.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  Future<void> _pickFromDevice() async {
    setState(() => _isPickingImage = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop image',
            toolbarColor: Theme.of(context).colorScheme.surface,
            toolbarWidgetColor: Theme.of(context).colorScheme.onSurface,
            activeControlsWidgetColor: Theme.of(context).colorScheme.primary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop image',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      final source = cropped != null ? File(cropped.path) : File(picked.path);
      final bytes = await source.readAsBytes();
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'goal_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destFile = File('${dir.path}/goal_images/$fileName');
      await destFile.parent.create(recursive: true);
      await destFile.writeAsBytes(bytes, flush: true);
      setState(() {
        _selectedImageUrl = destFile.path;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final target = double.tryParse(_targetController.text.replaceAll(',', '')) ?? 0;
    if (target <= 0) return;

    if (_isEdit) {
      final updated = widget.goal!.copyWith(
        name: _nameController.text.trim(),
        targetAmount: target,
        color: _selectedColor.toARGB32(),
        icon: _selectedIcon,
        imageUrl: Value(_selectedImageUrl),
        deadline: Value(_deadline),
      );
      await appDatabase.updateGoal(updated);
    } else {
      await appDatabase.createGoal(
        GoalsCompanion.insert(
          name: _nameController.text.trim(),
          targetAmount: target,
          color: _selectedColor.toARGB32(),
          icon: Value(_selectedIcon),
          imageUrl: Value(_selectedImageUrl),
          deadline: Value(_deadline),
        ),
      );
    }
    if (mounted) context.pop();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Goal' : 'New Goal'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Goal name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Target amount'),
                validator: (v) {
                  final val = double.tryParse(v?.replaceAll(',', '') ?? '');
                  if (val == null || val <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 22),
              Text('Goal image', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _isPickingImage ? null : _pickFromDevice,
                icon: _isPickingImage
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.photo_library_rounded),
                label: const Text('Choose image from gallery'),
              ),
              if (_selectedImageUrl != null) ...[
                const SizedBox(height: 12),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GoalImage(
                        imageUrl: _selectedImageUrl,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        fallback: Container(
                          height: 140,
                          color: cs.surfaceContainerHighest,
                          child: const Center(child: Icon(Icons.broken_image_rounded, size: 40)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filledTonal(
                        onPressed: () async {
                          final old = _selectedImageUrl;
                          if (old != null && !old.startsWith('http') && !old.startsWith('data:')) {
                            try { await File(old).delete(); } catch (_) {}
                          }
                          setState(() => _selectedImageUrl = null);
                        },
                        icon: const Icon(Icons.clear_rounded),
                        tooltip: 'Remove image',
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              Text('Color', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: GoalOptions.palette.map((c) {
                  final selected = c == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedColor = c;
                      _showHexInput = false;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                            : null,
                        boxShadow: selected
                            ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 1)]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() {
                  _showHexInput = !_showHexInput;
                  if (_showHexInput) {
                    _hexController.text = _selectedColor.value.toRadixString(16).substring(2).toUpperCase();
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Custom color',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
                      ),
                      const SizedBox(width: 4),
                      Icon(_showHexInput ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18, color: Theme.of(context).colorScheme.outline),
                    ],
                  ),
                ),
              ),
              if (_showHexInput) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('#', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.outline)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _hexController,
                        maxLength: 6,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'FF6750A4',
                          hintStyle: TextStyle(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (v) {
                          if (v.length == 6) {
                            final parsed = int.tryParse(v, radix: 16);
                            if (parsed != null) {
                              setState(() => _selectedColor = Color(0xFF000000 | parsed));
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              Text('Icon', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: GoalOptions.icons.map((icon) {
                  final selected = icon.codePoint == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon.codePoint),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: selected
                            ? _selectedColor.withValues(alpha: 0.2)
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: selected
                            ? Border.all(color: _selectedColor, width: 2)
                            : null,
                      ),
                      child: Icon(icon, color: selected ? _selectedColor : Theme.of(context).colorScheme.outline),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              ListTile(
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                leading: const Icon(Icons.calendar_today_rounded),
                title: Text(_deadline == null
                    ? 'Add a deadline (optional)'
                    : 'Deadline: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'),
                onTap: _pickDeadline,
                trailing: _deadline == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _deadline = null),
                      ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: InkWell(
                  onTap: _save,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            _isEdit ? 'Save changes' : 'Create goal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }
}
