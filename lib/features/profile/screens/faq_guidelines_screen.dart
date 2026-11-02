import 'package:flutter/material.dart';

class FaqGuidelinesScreen extends StatefulWidget {
  const FaqGuidelinesScreen({super.key});

  @override
  State<FaqGuidelinesScreen> createState() => _FaqGuidelinesScreenState();
}

class _FaqGuidelinesScreenState extends State<FaqGuidelinesScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Earnings & Pay',
    'Orders & Dispatch',
    'Safety & Rules',
    'Documents',
  ];

  final List<Map<String, dynamic>> _allFaqs = [
    {
      'category': 'Earnings & Pay',
      'question': 'When and how do I receive my payouts?',
      'answer':
          'Earnings are tallied daily and automatically transferred to your linked bank account every Monday at midnight. You can also use "Express Cashout" from the Earnings tab for instantaneous transfers to your debit card (subject to a nominal 1% processing fee).',
      'icon': Icons.payments_rounded,
    },
    {
      'category': 'Earnings & Pay',
      'question': 'How are hazard and special equipment fees calculated?',
      'answer':
          'Heavy recovery, winching, low-clearance vehicle extraction, or adverse weather situations automatically include hazard and equipment surcharges (\$20 - \$50 extra). These fees are displayed transparently on the request card before you accept.',
      'icon': Icons.attach_money_rounded,
    },
    {
      'category': 'Earnings & Pay',
      'question': 'What compensation do I get if the customer cancels?',
      'answer':
          'If a customer cancels an order after you have been en route for more than 3 minutes, or after you arrive at the pickup location, a guaranteed cancellation fee (\$20 - \$35 depending on distance traveled) is credited to your wallet instantly.',
      'icon': Icons.cancel_outlined,
    },
    {
      'category': 'Orders & Dispatch',
      'question': 'How does my Driver Rating affect job assignments?',
      'answer':
          'Maintaining a rating of 4.8 or above qualifies you for Gold Tier priority dispatch. Gold Tier captains receive high-value commercial jobs and highway emergency requests 15 seconds before general broadcast.',
      'icon': Icons.star_rounded,
    },
    {
      'category': 'Orders & Dispatch',
      'question': 'Can I decline a request without penalty?',
      'answer':
          'Yes, you can tap "Pass" on any incoming job. However, keeping an Acceptance Rate above 85% ensures you remain eligible for weekly order bonuses. When you need a break, switch your status to "Offline" to pause requests.',
      'icon': Icons.toggle_off_rounded,
    },
    {
      'category': 'Orders & Dispatch',
      'question': 'What should I do if the vehicle is heavier than expected?',
      'answer':
          'Do not attempt an unsafe tow. Tap "Report Issue" on the active job screen and select "GVWR Exceeded". Our dispatch team will immediately reroute a heavy-duty rotator or flatbed and credit you for your arrival.',
      'icon': Icons.warning_amber_rounded,
    },
    {
      'category': 'Safety & Rules',
      'question': 'What safety gear is mandatory on every dispatch?',
      'answer':
          'Drivers must wear an ANSI Class 3 high-visibility vest and steel-toe work boots. Your truck must be equipped with working amber roof strobes, 4 heavy-duty safety wheel chocks, reflective cones, and a fully charged fire extinguisher.',
      'icon': Icons.security_rounded,
    },
    {
      'category': 'Safety & Rules',
      'question': 'What is the highway shoulder safety protocol?',
      'answer':
          '1. Turn on strobe flashers 100 meters before stopping.\n2. Position your tow truck at a 45-degree blocker angle to protect the scene.\n3. Place warning triangles 50ft and 100ft behind the breakdown vehicle.\n4. Ensure all occupants stay safely behind the roadside guardrail.',
      'icon': Icons.traffic_rounded,
    },
    {
      'category': 'Documents',
      'question': 'How do I upload renewed documents (RC, DL, Insurance)?',
      'answer':
          'Go to "My Profile" > "Documents (RC, DL, PAN)". Tap on the expiring item, take a clear photo showing all 4 corners without glare, and submit. Verification is completed within 2 hours.',
      'icon': Icons.assignment_outlined,
    },
    {
      'category': 'Documents',
      'question': 'Why was my submitted document rejected?',
      'answer':
          'Documents are usually rejected due to blurry text, cropped corners, expired validity dates, or name mismatches. Ensure the name on your Commercial Driver License exactly matches your banking and registration records.',
      'icon': Icons.error_outline_rounded,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredFaqs {
    return _allFaqs.where((faq) {
      final matchesCategory = _selectedCategory == 'All' || faq['category'] == _selectedCategory;
      final query = _searchQuery.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          (faq['question'] as String).toLowerCase().contains(query) ||
          (faq['answer'] as String).toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final faqs = _filteredFaqs;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'FAQs & Guidelines',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
              decoration: InputDecoration(
                hintText: 'Search policies, payouts, safety...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280), size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. Horizontal Category Filter Chips
          Container(
            color: Colors.white,
            height: 48,
            padding: const EdgeInsets.only(bottom: 10),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: Colors.black,
                  backgroundColor: const Color(0xFFF3F4F6),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                  showCheckmark: false,
                  onSelected: (_) {
                    setState(() => _selectedCategory = cat);
                  },
                );
              },
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

          // 3. FAQs List
          Expanded(
            child: faqs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 52, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 12),
                        const Text(
                          'No matching topics found',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try searching with a different keyword',
                          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedCategory = 'All';
                            });
                          },
                          child: const Text('Reset Filters'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: faqs.length,
                    itemBuilder: (context, idx) {
                      final item = faqs[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                color: const Color(0xFF2563EB),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              item['question'] as String,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  item['answer'] as String,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 4. Bottom Support Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Still have questions?',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      Text(
                        'Our 24/7 driver team is here to assist.',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Connecting to 24/7 Driver Support Agent...')),
                    );
                  },
                  icon: const Icon(Icons.headset_mic_rounded, size: 16, color: Colors.white),
                  label: const Text('Contact Support', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
