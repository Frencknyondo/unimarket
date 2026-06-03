import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';
import '../models/product_listing.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selectedPeriod = 'month'; // 'day', 'month', 'year'
  List<OrderModel> orders = [];
  List<ProductListing> listings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);

      // Fetch orders
      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      final fetchedOrders = ordersSnap.docs.map((doc) {
        final data = doc.data();
        data['orderId'] = doc.id;
        return OrderModel.fromMap(data);
      }).toList();

      // Fetch listings
      final listingsSnap = await FirebaseFirestore.instance
          .collection('listings')
          .get();

      final fetchedListings = listingsSnap.docs.map((doc) {
        final data = doc.data();
        data['productId'] = doc.id;
        return ProductListing.fromMap(data);
      }).toList();

      if (!mounted) return;
      setState(() {
        orders = fetchedOrders;
        listings = fetchedListings;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      setState(() => isLoading = false);
    }
  }

  Map<String, List<ChartData>> _generateChartData() {
    final today = DateTime.now();
    final dayData = <String, int>{};
    final monthData = <String, int>{};
    final yearData = <String, int>{};

    // Initialize with last 5 days (including weekends)
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (int i = 4; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayName = dayNames[date.weekday - 1];
      dayData[dayName] = 0;
    }

    // Initialize last 6 months
    for (int i = 5; i >= 0; i--) {
      final date = today.subtract(Duration(days: 30 * i));
      monthData[_getMonthName(date.month)] = 0;
    }

    // Initialize last 5 years
    for (int i = 4; i >= 0; i--) {
      yearData['${today.year - i}'] = 0;
    }

    // Count listings by date
    for (final listing in listings) {
      if (listing.createdAt != null) {
        final date = listing.createdAt!;
        final monthName = _getMonthName(date.month);
        final year = date.year.toString();

        monthData[monthName] = (monthData[monthName] ?? 0) + 1;
        yearData[year] = (yearData[year] ?? 0) + 1;

        if (date.isAfter(today.subtract(const Duration(days: 5)))) {
          final dayName = [
            'Mon',
            'Tue',
            'Wed',
            'Thu',
            'Fri',
            'Sat',
            'Sun',
          ][date.weekday - 1];
          dayData[dayName] = (dayData[dayName] ?? 0) + 1;
        }
      }
    }

    return {
      'day': dayData.entries.map((e) => ChartData(e.key, e.value)).toList(),
      'month': monthData.entries.map((e) => ChartData(e.key, e.value)).toList(),
      'year': yearData.entries.map((e) => ChartData(e.key, e.value)).toList(),
    };
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Future<void> _exportToPDF() async {
    if (isLoading) return;

    try {
      final pdf = pw.Document();
      final generatedAt = DateTime.now();
      final topCategories = _getTopCategories();
      final priceDistribution = _getHighestPriced();
      final recentOrders = orders.take(12).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (context) => [
            _pdfHeader(generatedAt),
            pw.SizedBox(height: 18),
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _pdfMetric('Total Listings', listings.length.toString()),
                _pdfMetric('Total Orders', orders.length.toString()),
                _pdfMetric(
                  'Revenue',
                  'Tsh ${_calculateRevenue().toStringAsFixed(0)}',
                ),
                _pdfMetric('Categories', _getCategoryCount().toString()),
              ],
            ),
            pw.SizedBox(height: 24),
            _pdfSectionTitle('Top Categories'),
            _pdfBreakdownTable(topCategories),
            pw.SizedBox(height: 18),
            _pdfSectionTitle('Price Distribution'),
            _pdfBreakdownTable(priceDistribution),
            pw.SizedBox(height: 18),
            _pdfSectionTitle('Recent Orders'),
            if (recentOrders.isEmpty)
              pw.Text('No orders available.')
            else
              pw.TableHelper.fromTextArray(
                border: null,
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFEEF2FF),
                ),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.all(7),
                headers: const [
                  'Date',
                  'Product',
                  'Buyer',
                  'Status',
                  'Amount',
                ],
                data: recentOrders
                    .map(
                      (order) => [
                        _formatDate(order.createdAt),
                        order.productTitle,
                        order.buyerName.isEmpty ? order.buyerEmail : order.buyerName,
                        order.status.toUpperCase(),
                        '${order.currency} ${order.totalPrice.toStringAsFixed(0)}',
                      ],
                    )
                    .toList(),
              ),
            pw.SizedBox(height: 18),
            _pdfSectionTitle('Report Notes'),
            pw.Text(
              'This report was generated from the current Firestore orders and listings data. It summarizes marketplace activity, revenue, category mix, and recent transactions for admin review.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
          footer: (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'UniMarket Admin Report - Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ),
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'unimarket-report-${_fileDate(generatedAt)}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export PDF: $e')));
    }
  }

  pw.Widget _pdfHeader(DateTime generatedAt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF1F2937),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'UniMarket Admin Report',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Marketplace performance and management summary',
                style: const pw.TextStyle(color: PdfColors.grey300),
              ),
            ],
          ),
          pw.Text(
            _formatDate(generatedAt),
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfMetric(String title, String value) {
    return pw.Container(
      width: 125,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _pdfBreakdownTable(List<(String, int, double)> items) {
    if (items.isEmpty) return pw.Text('No data available.');
    return pw.TableHelper.fromTextArray(
      border: null,
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFEEF2FF),
      ),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellPadding: const pw.EdgeInsets.all(8),
      headers: const ['Name', 'Count', 'Percentage'],
      data: items
          .map(
            (item) => [
              item.$1,
              item.$2.toString(),
              '${item.$3.toStringAsFixed(1)}%',
            ],
          )
          .toList(),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _fileDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final chartDataMap = _generateChartData();
    final data = chartDataMap[_selectedPeriod] ?? [];
    final maxValue = data.isEmpty
        ? 1
        : data.map((d) => d.value).reduce((a, b) => a > b ? a : b).toDouble();
    final effectiveMaxValue = maxValue <= 0 ? 1 : maxValue;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF4A3DE0)),
            tooltip: 'Export to PDF',
            onPressed: _exportToPDF,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI Cards
                    const Text(
                      'Key Metrics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _KPICard(
                            title: 'Total Listings',
                            value: listings.length.toString(),
                            icon: Icons.storefront_rounded,
                            change:
                                '+${(listings.length * 0.125).toStringAsFixed(0)}%',
                            isPositive: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KPICard(
                            title: 'Total Orders',
                            value: orders.length.toString(),
                            icon: Icons.shopping_bag_rounded,
                            change:
                                '+${(orders.length * 0.231).toStringAsFixed(0)}%',
                            isPositive: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _KPICard(
                            title: 'Revenue',
                            value:
                                '\$${_calculateRevenue().toStringAsFixed(0)}',
                            icon: Icons.trending_up_rounded,
                            change:
                                '+${(_calculateRevenue() * 0.187 / 1000).toStringAsFixed(0)}%',
                            isPositive: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KPICard(
                            title: 'Categories',
                            value: _getCategoryCount().toString(),
                            icon: Icons.category_rounded,
                            change: '+${_getCategoryCount()}',
                            isPositive: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Chart Section
                    const Text(
                      'Listings Performance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Period Selector
                    Wrap(
                      spacing: 8,
                      children: ['day', 'month', 'year'].map((period) {
                        final isSelected = _selectedPeriod == period;
                        return FilterChip(
                          label: Text(
                            period.replaceFirst(
                              period[0],
                              period[0].toUpperCase(),
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black54,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedPeriod = period);
                          },
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF4A3DE0),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF4A3DE0)
                                : Colors.black12,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Chart
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: data.isEmpty
                            ? const SizedBox(
                                height: 200,
                                child: Center(child: Text('No data available')),
                              )
                            : SizedBox(
                                height: 200,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: data.map((item) {
                                    final height = effectiveMaxValue == 0
                                        ? 0
                                        : (item.value / effectiveMaxValue) *
                                              140;
                                    return Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            item.value.toString(),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            height: height.toDouble(),
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF4A3DE0),
                                                  Color(0xFF6A5AE0),
                                                ],
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            item.label,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.black54,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Detailed Reports
                    const Text(
                      'Detailed Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailedReportCard(
                      title: 'Top Categories',
                      items: _getTopCategories(),
                    ),
                    const SizedBox(height: 12),
                    _DetailedReportCard(
                      title: 'Price Distribution',
                      items: _getHighestPriced(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  double _calculateRevenue() {
    return orders.fold(0.0, (total, order) => total + order.totalPrice);
  }

  int _getCategoryCount() {
    final categories = <String>{};
    for (final listing in listings) {
      categories.add(listing.category);
    }
    return categories.length;
  }

  List<(String, int, double)> _getTopCategories() {
    final categoryCount = <String, int>{};
    for (final listing in listings) {
      categoryCount[listing.category] =
          (categoryCount[listing.category] ?? 0) + 1;
    }

    final total = listings.length;
    final sorted = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(4)
        .map((e) => (e.key, e.value, (e.value / (total > 0 ? total : 1)) * 100))
        .toList();
  }

  List<(String, int, double)> _getHighestPriced() {
    final priceRanges = <String, int>{
      'Under \$100': 0,
      '\$100-\$500': 0,
      '\$500-\$1000': 0,
      'Over \$1000': 0,
    };

    for (final listing in listings) {
      if (listing.price < 100) {
        priceRanges['Under \$100'] = (priceRanges['Under \$100'] ?? 0) + 1;
      } else if (listing.price < 500) {
        priceRanges['\$100-\$500'] = (priceRanges['\$100-\$500'] ?? 0) + 1;
      } else if (listing.price < 1000) {
        priceRanges['\$500-\$1000'] = (priceRanges['\$500-\$1000'] ?? 0) + 1;
      } else {
        priceRanges['Over \$1000'] = (priceRanges['Over \$1000'] ?? 0) + 1;
      }
    }

    final total = listings.length;
    return priceRanges.entries
        .map((e) => (e.key, e.value, (e.value / (total > 0 ? total : 1)) * 100))
        .toList();
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String change;
  final bool isPositive;

  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.change,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEBFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF4A3DE0), size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 14,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    change,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailedReportCard extends StatelessWidget {
  final String title;
  final List<(String, int, double)> items;

  const _DetailedReportCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No data available'),
                  )
                : Column(
                    children: items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final (label, count, percentage) = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: idx < items.length - 1 ? 12 : 0,
                        ),
                        child: Column(
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
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$count (${percentage.toStringAsFixed(1)}%)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFEDEBFF),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4A3DE0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  final String label;
  final int value;

  ChartData(this.label, this.value);
}
