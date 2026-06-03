import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product_listing.dart';

/// Search service with fuzzy matching and suggestion support
class SearchService {
  static const _minSimilarityScore =
      0.6; // 60% similarity threshold for suggestions

  /// Levenshtein distance algorithm: measures difference between two strings
  /// Returns a similarity score between 0 (completely different) and 1 (identical)
  static double _levenshteinSimilarity(String a, String b) {
    final aLower = a.toLowerCase();
    final bLower = b.toLowerCase();
    final maxLen = [
      aLower.length,
      bLower.length,
    ].reduce((a, b) => a > b ? a : b);
    if (maxLen == 0) return 1.0;

    final distance = _levenshteinDistance(aLower, bLower);
    return 1 - (distance / maxLen);
  }

  /// Calculates the Levenshtein distance between two strings
  static int _levenshteinDistance(String a, String b) {
    final aLen = a.length;
    final bLen = b.length;
    final dp = List<List<int>>.generate(
      aLen + 1,
      (i) => List<int>.generate(bLen + 1, (j) => 0),
    );

    for (int i = 0; i <= aLen; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= bLen; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= aLen; i++) {
      for (int j = 1; j <= bLen; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1, // deletion
          dp[i][j - 1] + 1, // insertion
          dp[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return dp[aLen][bLen];
  }

  /// Searches products by query across title, description, and category
  /// Returns matched products
  static Future<List<ProductListing>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final queryLower = query.toLowerCase().trim();
      final tokens = queryLower
          .split(RegExp(r'\s+'))
          .map((token) => token.trim())
          .where((token) => token.isNotEmpty)
          .toList();

      final collection = FirebaseFirestore.instance.collection('listings');
      final resultMap = <String, ProductListing>{};

      final titleQuery = collection
          .orderBy('title_lower')
          .startAt([queryLower])
          .endAt(['$queryLower\uf8ff'])
          .limit(100);

      final futures = <Future<QuerySnapshot>>[titleQuery.get()];

      if (tokens.isNotEmpty) {
        futures.add(
          collection
              .where('keywords', arrayContainsAny: tokens)
              .limit(100)
              .get(),
        );
      }

      final snapshots = await Future.wait(futures);

      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          data['productId'] = doc.id;
          final product = ProductListing.fromMap(data);
          resultMap[product.productId] = product;
        }
      }

      if (resultMap.isEmpty && queryLower.length >= 2) {
        final fallbackSnapshot = await collection.limit(200).get();
        for (final doc in fallbackSnapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          final title = (data['title'] as String?)?.toLowerCase() ?? '';
          final description =
              (data['description'] as String?)?.toLowerCase() ?? '';
          final category = (data['category'] as String?)?.toLowerCase() ?? '';
          final location = (data['location'] as String?)?.toLowerCase() ?? '';
          final specificLocation =
              (data['specificLocation'] as String?)?.toLowerCase() ?? '';
          final sellerName =
              (data['sellerName'] as String?)?.toLowerCase() ?? '';

          if (title.contains(queryLower) ||
              description.contains(queryLower) ||
              category.contains(queryLower) ||
              location.contains(queryLower) ||
              specificLocation.contains(queryLower) ||
              sellerName.contains(queryLower)) {
            data['productId'] = doc.id;
            final product = ProductListing.fromMap(data);
            resultMap[product.productId] = product;
          }
        }
      }

      return resultMap.values.toList();
    } catch (e) {
      debugPrint('Search error: $e');
      return [];
    }
  }

  /// Gets spelling suggestions based on all available products
  /// Uses Levenshtein distance to find similar terms
  static Future<List<String>> getSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final queryLower = query.toLowerCase().trim();
      final snapshot = await FirebaseFirestore.instance
          .collection('listings')
          .limit(500)
          .get();

      final suggestions = <String, double>{};
      double bestTitleSim = 0.0;
      String? bestTitle;

      for (final doc in snapshot.docs) {
        final product = ProductListing.fromMap(doc.data());

        // Extract words from title, category and seller name
        final titleWords = product.title.toLowerCase().split(RegExp(r'\s+'));
        final categoryWords = product.category.toLowerCase().split(
          RegExp(r'\s+'),
        );
        final sellerWords = product.sellerName.toLowerCase().split(
          RegExp(r'\s+'),
        );

        // Track whole-title similarity for a friendly "Did you mean" fallback
        final titleSim = _levenshteinSimilarity(
          queryLower,
          product.title.toLowerCase(),
        );
        if (titleSim > bestTitleSim) {
          bestTitleSim = titleSim;
          bestTitle = product.title;
        }

        for (final word in [...titleWords, ...categoryWords, ...sellerWords]) {
          if (word.isNotEmpty && word != queryLower) {
            final similarity = _levenshteinSimilarity(queryLower, word);
            if (similarity >= _minSimilarityScore) {
              // Keep the highest similarity score for each suggestion
              if (!suggestions.containsKey(word) ||
                  suggestions[word]! < similarity) {
                suggestions[word] = similarity;
              }
            }
          }
        }
      }

      // Sort by similarity score (descending) and return top 5
      final sorted = suggestions.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.take(5).map((e) => e.key).toList();

      // If no small-word suggestions but a reasonably matching full title exists, return it
      if (top.isEmpty && bestTitle != null && bestTitleSim > 0.25) {
        return [bestTitle];
      }

      return top;
    } catch (e) {
      debugPrint('Suggestions error: $e');
      return [];
    }
  }

  /// Hybrid search: returns both exact results and suggestions
  static Future<SearchResult> performSearch(String query) async {
    final products = await searchProducts(query);
    final suggestions = await getSuggestions(query);

    return SearchResult(
      query: query,
      products: products,
      suggestions: suggestions,
      hasExactResults: products.isNotEmpty,
    );
  }
}

/// Holds search results with suggestions
class SearchResult {
  final String query;
  final List<ProductListing> products;
  final List<String> suggestions;
  final bool hasExactResults;

  SearchResult({
    required this.query,
    required this.products,
    required this.suggestions,
    required this.hasExactResults,
  });

  bool get hasSuggestions => suggestions.isNotEmpty;
}
