part of '../settings_screen.dart';

// ── Currency Picker Sheet ─────────────────────────────────────────────────────

class _CurrencyPickerSheet extends StatefulWidget {
  final SettingsProvider settings;
  const _CurrencyPickerSheet({required this.settings});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const Map<String, List<String>> _regions = {
    'Americas': ['USD', 'CAD', 'AUD', 'BRL', 'MXN'],
    'Europe':   ['EUR', 'GBP', 'CHF', 'RUB', 'TRY', 'SEK', 'NOK'],
    'Middle East & Africa': ['AED', 'SAR', 'IRR', 'AFN', 'IQD', 'KWD', 'QAR'],
    'Asia': ['JPY', 'CNY', 'KRW', 'INR', 'PKR', 'BDT', 'THB', 'VND', 'SGD', 'HKD'],
  };

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme  = Theme.of(context);
    final allCurrencies = {
      for (final c in SettingsProvider.currencies) c['code']!: c['label']!
    };

    final isSearching = _query.isNotEmpty;
    final filtered = isSearching
        ? SettingsProvider.currencies
        .where((c) =>
    c['code']!.toLowerCase().contains(_query) ||
        c['label']!.toLowerCase().contains(_query))
        .toList()
        : <Map<String, String>>[];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                children: [
                  Center(child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2)),
                  )),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Select Currency',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(widget.settings.currency,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) =>
                        setState(() => _query = v.toLowerCase().trim()),
                    decoration: InputDecoration(
                      hintText: 'Search currency (e.g. USD, Euro, Yen...)',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              child: isSearching
                  ? filtered.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 48,
                        color: theme.colorScheme.onSurface
                            .withOpacity(0.2)),
                    const SizedBox(height: 12),
                    Text('No currency found',
                        style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.4))),
                  ],
                ),
              )
                  : ListView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final code  = filtered[i]['code']!;
                  final label = filtered[i]['label']!;
                  return _CurrencyTile(
                    code: code, label: label,
                    isSelected: widget.settings.currency == code,
                    theme: theme, isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      widget.settings.setCurrency(code);
                    },
                  );
                },
              )
                  : ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: _regions.entries.map((region) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                        child: Text(region.key.toUpperCase(),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: theme.colorScheme.primary)),
                      ),
                      ...region.value.map((code) {
                        final label = allCurrencies[code] ?? code;
                        return _CurrencyTile(
                          code: code, label: label,
                          isSelected: widget.settings.currency == code,
                          theme: theme, isDark: isDark,
                          onTap: () {
                            Navigator.pop(context);
                            widget.settings.setCurrency(code);
                          },
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
