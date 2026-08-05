part of '../settings_screen.dart';

// ── Categories Page ───────────────────────────────────────────────────────────

class _CategoriesPage extends StatelessWidget {
  const _CategoriesPage();

  @override
  Widget build(BuildContext context) {
    final cats   = context.watch<CategoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
        isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        title: const Text('Categories'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: cats.categories.map((cat) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(cat.colorValue).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CategoryIcons.resolve(cat.icon),
                    color: Color(cat.colorValue), size: 20),
              ),
              title: Text(cat.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: cat.isCustom
                  ? IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red),
                onPressed: () => cats.deleteCustomCategory(cat.id),
              )
                  : Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(cat.colorValue).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Default',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(cat.colorValue),
                        fontWeight: FontWeight.w600)),
              ),
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategory(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddCategory(BuildContext context) {
    final nameCtrl = TextEditingController();
    String selectedIconKey = 'star';
    Color  selectedColor   = const Color(0xFF1E3A5F);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New Category',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Category name',
                        prefixIcon: Icon(Icons.label_rounded)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Icon',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: CategoryIcons.pickerIcons.map((item) {
                      final key        = item['key'] as String;
                      final icon       = item['icon'] as IconData;
                      final isSelected = selectedIconKey == key;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => selectedIconKey = key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? selectedColor.withOpacity(0.15)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? selectedColor
                                  : Colors.grey.withOpacity(0.3),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon,
                              color: isSelected
                                  ? selectedColor : Colors.grey,
                              size: 24),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Color',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: [
                      const Color(0xFF1E3A5F), const Color(0xFF4A90E2),
                      const Color(0xFF2ECC71), const Color(0xFFE57373),
                      const Color(0xFFFF9800), const Color(0xFF9C27B0),
                      const Color(0xFF00BCD4), const Color(0xFFFF6B6B),
                      const Color(0xFF4ECDC4), const Color(0xFFFFBE76),
                      const Color(0xFF96CEB4), const Color(0xFFE91E63),
                    ].map((color) {
                      final isSelected =
                          selectedColor.value == color.value;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => selectedColor = color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8, spreadRadius: 2)]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        ctx.read<CategoryProvider>().addCustomCategory(
                          CategoryModel(
                            id: AppUtils.generateId(),
                            name: name,
                            colorValue: selectedColor.value,
                            icon: selectedIconKey,
                            isCustom: true,
                          ),
                        );
                        Navigator.pop(ctx);
                      },
                      child: const Text('Add Category'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
