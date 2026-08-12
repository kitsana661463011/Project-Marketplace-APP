import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/shop.dart';
import '../services/review_service.dart';
import '../services/api_service.dart';

class ReviewItem {
  final int reviewId;
  final String userName;
  final String userAvatar;
  final double rating;
  final String timeAgo;
  final DateTime? reviewDate;
  final String reviewText;
  final List<String> images;
  int likes;
  bool isLiked;
  bool isDisliked;

  ReviewItem({
    required this.reviewId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.timeAgo,
    this.reviewDate,
    required this.reviewText,
    this.images = const [],
    this.likes = 0,
    this.isLiked = false,
    this.isDisliked = false,
  });
}

class ShopReviewsScreen extends StatefulWidget {
  const ShopReviewsScreen({super.key});

  @override
  State<ShopReviewsScreen> createState() => _ShopReviewsScreenState();
}

class _ShopReviewsScreenState extends State<ShopReviewsScreen> {
  late Shop _shop;
  int _originTabIndex = 0;
  bool _isLatestTab = true;
  bool _isLoading = true;

  // Rating breakdown values
  int _totalReviews = 124;
  double _averageRating = 4.8;
  final List<double> _ratingPercentages = [
    0.70,
    0.20,
    0.05,
    0.03,
    0.02,
  ]; // 5, 4, 3, 2, 1 stars

  late List<ReviewItem> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Shop) {
      _shop = args;
      _originTabIndex = 0;
    } else if (args is Map) {
      _shop = args['shop'] as Shop;
      _originTabIndex = args['tabIndex'] as int? ?? 0;
    }
    _loadReviews(_shop.shopId);
  }

  Future<void> _loadReviews(int? shopId) async {
    if (shopId == null) {
      setState(() {
        _reviews = [];
        _totalReviews = 0;
        _averageRating = 0.0;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    final apiReviews = await ReviewService.getReviewsByShop(shopId);

    if (mounted) {
      setState(() {
        if (apiReviews.isNotEmpty) {
          _reviews = apiReviews.map((json) {
            final user = json['user'] as Map<String, dynamic>?;
            final String username = user?['username'] ?? 'ผู้ใช้ทั่วไป';
            final String profileImgStr =
                user?['profile_image']?.toString() ?? '';
            final String avatar = profileImgStr.isNotEmpty
                ? ApiService.getImagePath(profileImgStr)
                : '';

            DateTime? parsedDate;
            String timeAgo = 'ไม่ระบุเวลา';
            if (json['review_date'] != null) {
              try {
                parsedDate = DateTime.parse(json['review_date']);
                final diff = DateTime.now().difference(parsedDate);
                if (diff.inDays > 30) {
                  timeAgo = '${(diff.inDays / 30).floor()} เดือนที่แล้ว';
                } else if (diff.inDays > 0) {
                  timeAgo = '${diff.inDays} วันที่แล้ว';
                } else if (diff.inHours > 0) {
                  timeAgo = '${diff.inHours} ชั่วโมงที่แล้ว';
                } else {
                  timeAgo = 'เมื่อสักครู่';
                }
              } catch (_) {}
            }

            final imagesValue = json['review_images'];
            List<String> reviewImages = [];
            if (imagesValue is String && imagesValue.isNotEmpty) {
              try {
                final parsedImages = jsonDecode(imagesValue);
                if (parsedImages is List) {
                  reviewImages = parsedImages.map((e) => e.toString()).toList();
                }
              } catch (_) {
                reviewImages = imagesValue
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
              }
            } else if (imagesValue is List) {
              reviewImages = imagesValue.map((e) => e.toString()).toList();
            }

            return ReviewItem(
              reviewId: json['review_id'] as int? ?? 0,
              userName: username,
              userAvatar: avatar,
              rating: (json['rating'] as num? ?? 5.0).toDouble(),
              timeAgo: timeAgo,
              reviewDate: parsedDate,
              reviewText: json['comment'] ?? '',
              images: reviewImages
                  .map((src) => ApiService.getImagePath(src))
                  .toList(),
              likes: (json['likes'] ?? 0) as int,
            );
          }).toList();

          // Recalculate stats dynamically
          _totalReviews = _reviews.length;
          double totalRating = 0;
          final List<int> counts = [0, 0, 0, 0, 0];
          for (var r in _reviews) {
            totalRating += r.rating;
            int starIdx = 5 - r.rating.round();
            if (starIdx >= 0 && starIdx < 5) {
              counts[starIdx]++;
            }
          }
          _averageRating = _totalReviews > 0
              ? totalRating / _totalReviews
              : 0.0;
          for (int i = 0; i < 5; i++) {
            _ratingPercentages[i] = _totalReviews > 0
                ? counts[i] / _totalReviews
                : 0.0;
          }
        } else {
          _reviews = [];
          _totalReviews = 0;
          _averageRating = 0.0;
          _ratingPercentages[0] = 0.0;
          _ratingPercentages[1] = 0.0;
          _ratingPercentages[2] = 0.0;
          _ratingPercentages[3] = 0.0;
          _ratingPercentages[4] = 0.0;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort reviews based on tab selection
    final sortedReviews = List<ReviewItem>.from(_reviews);
    if (_isLatestTab) {
      // Sort by newest reviewDate / reviewId descending
      sortedReviews.sort((a, b) {
        if (a.reviewDate != null && b.reviewDate != null) {
          int cmpDate = b.reviewDate!.compareTo(a.reviewDate!);
          if (cmpDate != 0) return cmpDate;
        }
        return b.reviewId.compareTo(a.reviewId);
      });
    } else {
      // Sort by likes descending first (most liked on top), then rating descending, then reviewDate/reviewId descending
      sortedReviews.sort((a, b) {
        int cmpLikes = b.likes.compareTo(a.likes);
        if (cmpLikes != 0) return cmpLikes;
        int cmpRating = b.rating.compareTo(a.rating);
        if (cmpRating != 0) return cmpRating;
        if (a.reviewDate != null && b.reviewDate != null) {
          int cmpDate = b.reviewDate!.compareTo(a.reviewDate!);
          if (cmpDate != 0) return cmpDate;
        }
        return b.reviewId.compareTo(a.reviewId);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating Overview Section
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    child: Row(
                      children: [
                        // Left Rating Summary Info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _averageRating.toStringAsFixed(1),
                                  style: GoogleFonts.outfit(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  ' / 5',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Row of Stars
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                final starVal = index + 1;
                                if (starVal <= _averageRating.floor()) {
                                  return const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  );
                                } else if (starVal - 1 < _averageRating &&
                                    starVal > _averageRating) {
                                  return const Icon(
                                    Icons.star_half,
                                    color: Colors.amber,
                                    size: 20,
                                  );
                                } else {
                                  return const Icon(
                                    Icons.star_border,
                                    color: Colors.amber,
                                    size: 20,
                                  );
                                }
                              }),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_totalReviews รีวิวทั้งหมด',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        // Right Rating Breakdown Chart Bar
                        Expanded(
                          child: Column(
                            children: List.generate(5, (index) {
                              final starsCount = 5 - index;
                              final percent = _ratingPercentages[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2.0,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      child: Text(
                                        starsCount.toString(),
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: percent,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E88E5),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '${(percent * 100).toInt()}%',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: const Color(0xFF64748B),
                                        ),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Write Review Action Button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/write_review',
                          arguments: {
                            'shop': _shop,
                            'tabIndex': _originTabIndex,
                          },
                        );
                        if (result == true) {
                          _loadReviews(_shop.shopId);
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'เขียนรีวิวของคุณ',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Shop Header Title in Reviews Screen
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      '${_shop.shopName} (${_shop.shopName == 'สยาม ดีไลท์' ? 'Siam Delight' : 'Shop Detail'})',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),

                  // Tabs for Latest and Highest Rating
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Latest Tab Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isLatestTab = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _isLatestTab
                                        ? const Color(0xFF1E88E5)
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Text(
                                'ล่าสุด',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _isLatestTab
                                      ? const Color(0xFF1E88E5)
                                      : const Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        // Highest Rating Tab Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isLatestTab = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: !_isLatestTab
                                        ? const Color(0xFF1E88E5)
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Text(
                                'คะแนนสูงสุด',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: !_isLatestTab
                                      ? const Color(0xFF1E88E5)
                                      : const Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reviews List Card Builder
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: sortedReviews.length,
                    itemBuilder: (context, index) {
                      final review = sortedReviews[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Info & Stars Header Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFFE4E6EB),
                                  child: review.userAvatar.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            review.userAvatar,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.person,
                                                      color: Color(0xFF8A8D91),
                                                      size: 24,
                                                    ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          color: Color(0xFF8A8D91),
                                          size: 24,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review.userName,
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        review.timeAgo,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Rating Stars Row on the Right
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < review.rating.floor()
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Review Body text
                            Text(
                              review.reviewText,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: const Color(0xFF0F172A),
                                height: 1.5,
                              ),
                            ),
                            // Review Images Row (if any)
                            if (review.images.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: review.images.length,
                                  itemBuilder: (context, imgIndex) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          review.images[imgIndex],
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            // Likes, Dislikes and Report Actions Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    // Like Icon Button
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (review.isLiked) {
                                            review.likes -= 1;
                                            review.isLiked = false;
                                          } else {
                                            review.likes += 1;
                                            review.isLiked = true;
                                            if (review.isDisliked) {
                                              review.isDisliked = false;
                                            }
                                          }
                                        });
                                      },
                                      child: Icon(
                                        review.isLiked
                                            ? Icons.thumb_up
                                            : Icons.thumb_up_outlined,
                                        size: 18,
                                        color: review.isLiked
                                            ? const Color(0xFF1E88E5)
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (review.likes > 0)
                                      Text(
                                        review.likes.toString(),
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: const Color(0xFF64748B),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    const SizedBox(width: 16),
                                    // Dislike Icon Button
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (review.isDisliked) {
                                            review.isDisliked = false;
                                          } else {
                                            review.isDisliked = true;
                                            if (review.isLiked) {
                                              review.likes -= 1;
                                              review.isLiked = false;
                                            }
                                          }
                                        });
                                      },
                                      child: Icon(
                                        review.isDisliked
                                            ? Icons.thumb_down
                                            : Icons.thumb_down_outlined,
                                        size: 18,
                                        color: review.isDisliked
                                            ? const Color(0xFFE11D48)
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                                // Report comment action
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/report_comment',
                                      arguments: review,
                                    );
                                  },
                                  child: Text(
                                    'รายงานความคิดเห็น',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: const Color(0xFFE11D48),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: NavigationBar(
            selectedIndex: _originTabIndex,
            onDestinationSelected: (index) {
              Navigator.pop(context, index);
            },
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF1E88E5).withValues(alpha: 0.12),
            height: 70,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: Icon(
                  Icons.home,
                  size: 24,
                  color: Color(0xFF1E88E5),
                ),
                label: 'หน้าหลัก',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.explore_outlined,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: Icon(
                  Icons.explore,
                  size: 24,
                  color: Color(0xFF1E88E5),
                ),
                label: 'แผนที่ตลาด',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.favorite_outline,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: Icon(
                  Icons.favorite,
                  size: 24,
                  color: Color(0xFF1E88E5),
                ),
                label: 'ติดตาม',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline,
                  size: 24,
                  color: Color(0xFF64748B),
                ),
                selectedIcon: Icon(
                  Icons.person,
                  size: 24,
                  color: Color(0xFF1E88E5),
                ),
                label: 'โปรไฟล์',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
