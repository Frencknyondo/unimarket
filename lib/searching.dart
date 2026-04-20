import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _selectedPriceRange = 'Any Price';
  String _selectedCondition = 'Any Condition';
  String _selectedSortBy = 'Newest First';

  static const List<String> _categories = [
    'All',
    'Textbooks',
    'Electronics',
    'Furniture',
    'Clothing',
    'Medicine',
    'Beauty',
    'Baby',
    'Stationary',
    'Food',
  ];

  static const List<String> _priceRangeOptions = [
    'Any Price',
    'Under GH₵10',
    'GH₵10 - GH₵50',
    'Above GH₵50',
  ];

  static const List<String> _conditionOptions = [
    'Any Condition',
    'Brand New',
    'Like New',
    'Good',
    'Fair',
  ];

  static const List<String> _sortOptions = [
    'Newest First',
    'Price: Low to High',
    'Price: High to Low',
    'Most Popular',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: _BuildFilterSheet(
              selectedCategory: _selectedCategory,
              selectedPriceRange: _selectedPriceRange,
              selectedCondition: _selectedCondition,
              selectedSortBy: _selectedSortBy,
              onCategorySelected: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              onPriceRangeSelected: (value) {
                setState(() {
                  _selectedPriceRange = value;
                });
              },
              onConditionSelected: (value) {
                setState(() {
                  _selectedCondition = value;
                });
              },
              onSortBySelected: (value) {
                setState(() {
                  _selectedSortBy = value;
                });
              },
              onClearAll: () {
                setState(() {
                  _selectedCategory = 'All';
                  _selectedPriceRange = 'Any Price';
                  _selectedCondition = 'Any Condition';
                  _selectedSortBy = 'Newest First';
                });
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedFilters = <String>[];
    if (_selectedCategory != 'All') selectedFilters.add(_selectedCategory);
    if (_selectedPriceRange != 'Any Price') {
      selectedFilters.add(_selectedPriceRange);
    }
    if (_selectedCondition != 'Any Condition') {
      selectedFilters.add(_selectedCondition);
    }
    if (_selectedSortBy != 'Newest First') selectedFilters.add(_selectedSortBy);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Search',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              hintText: 'Search for textbooks, electronics...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  width: 56,
                  child: ElevatedButton(
                    onPressed: _openFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A3DE0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.filter_list_rounded, size: 26),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Filter preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            if (selectedFilters.isEmpty)
              const Text(
                'No filters applied yet. Tap the filter button to set options.',
                style: TextStyle(color: Colors.black54, fontSize: 15),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: selectedFilters
                    .map(
                      (value) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAE8FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4A3DE0),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.search_off_rounded,
                      size: 90,
                      color: Color(0xFFE5E7EB),
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Search for items or apply filters',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Use the search bar and filter icon to narrow down listings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildFilterSheet extends StatelessWidget {
  final String selectedCategory;
  final String selectedPriceRange;
  final String selectedCondition;
  final String selectedSortBy;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onPriceRangeSelected;
  final ValueChanged<String> onConditionSelected;
  final ValueChanged<String> onSortBySelected;
  final VoidCallback onClearAll;

  const _BuildFilterSheet({
    required this.selectedCategory,
    required this.selectedPriceRange,
    required this.selectedCondition,
    required this.selectedSortBy,
    required this.onCategorySelected,
    required this.onPriceRangeSelected,
    required this.onConditionSelected,
    required this.onSortBySelected,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 60,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Filters',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
            TextButton(
              onPressed: onClearAll,
              child: const Text(
                'Clear All',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A3DE0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Category',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _SearchPageState._categories.map((label) {
            final isActive = label == selectedCategory;
            return _FilterOptionChip(
              label: label,
              isActive: isActive,
              onTap: () => onCategorySelected(label),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Price Range',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _SearchPageState._priceRangeOptions.map((label) {
            final isActive = label == selectedPriceRange;
            return _FilterOptionChip(
              label: label,
              isActive: isActive,
              onTap: () => onPriceRangeSelected(label),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Condition',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _SearchPageState._conditionOptions.map((label) {
            final isActive = label == selectedCondition;
            return _FilterOptionChip(
              label: label,
              isActive: isActive,
              onTap: () => onConditionSelected(label),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Sort By',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _SearchPageState._sortOptions.map((label) {
            final isActive = label == selectedSortBy;
            return _FilterOptionChip(
              label: label,
              isActive: isActive,
              onTap: () => onSortBySelected(label),
            );
          }).toList(),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4A3DE0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Browse with Filters',
                    style: TextStyle(
                      color: Color(0xFF4A3DE0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A3DE0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Apply Filters',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterOptionChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterOptionChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4A3DE0) : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
