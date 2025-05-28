import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourcesPage extends StatefulWidget {
  const ResourcesPage({super.key});

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> {
  final List<ResourceCategory> _categories = [
    ResourceCategory(
      title: 'Crisis Support',
      icon: Icons.emergency,
      color: Colors.redAccent,
      resources: [
        Resource(
          title: 'National Suicide Prevention Lifeline',
          description: '24/7 crisis support and suicide prevention',
          phone: '988',
          website: 'https://988lifeline.org',
          isEmergency: true,
        ),
        Resource(
          title: 'Crisis Text Line',
          description: 'Text HOME to 741741 for 24/7 crisis support',
          phone: '741741',
          website: 'https://www.crisistextline.org',
          isEmergency: true,
        ),
        Resource(
          title: 'NAMI Helpline',
          description: 'Mental health information and referrals',
          phone: '1-800-950-6264',
          website: 'https://www.nami.org/help',
        ),
      ],
    ),
    ResourceCategory(
      title: 'Self-Care Tools',
      icon: Icons.spa,
      color: Colors.greenAccent,
      resources: [
        Resource(
          title: 'Breathing Exercises',
          description: 'Guided breathing techniques for anxiety and stress',
          isInteractive: true,
          route: '/breathing-exercises',
        ),
        Resource(
          title: 'Sleep Hygiene Guide',
          description: 'Tips and techniques for better sleep',

          website: 'https://www.sleepfoundation.org/sleep-hygiene',
        ),
        Resource(
          title: 'Guided Meditation',
          description: 'Free guided meditations and mindfulness practices',
          isInteractive: true,
          route: '/guided-meditation',
        ),
      ],
    ),
    ResourceCategory(
      title: 'Mental Health Education',
      icon: Icons.school,
      color: Colors.blueAccent,
      resources: [
        Resource(
          title: 'Understanding Depression',
          description:
              'Comprehensive guide to recognizing and managing depression',
          website: 'https://www.nimh.nih.gov/health/topics/depression',
        ),
        Resource(
          title: 'Anxiety Disorders',
          description:
              'Learn about different types of anxiety and treatment options',
          website: 'https://adaa.org/understanding-anxiety',
        ),
        Resource(
          title: 'PTSD Resources',
          description: 'Information and support for post-traumatic stress',
          website: 'https://www.ptsd.va.gov/',
        ),
      ],
    ),
    ResourceCategory(
      title: 'Support Communities',
      icon: Icons.people,
      color: Colors.purpleAccent,
      resources: [
        Resource(
          title: 'Mental Health America',
          description: 'Online screening tools and support groups',
          website: 'https://www.mhanational.org',
        ),
        Resource(
          title: 'SMART Recovery',
          description: 'Self-help addiction recovery support groups',
          website: 'https://www.smartrecovery.org',
        ),
        Resource(
          title: 'The Mighty',
          description: 'Community for people facing health challenges',
          website: 'https://themighty.com',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resources', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF414345),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF414345),
              Color(0xFF232526),
              Color.fromARGB(255, 0, 0, 0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mental Health Resources',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find support, tools, and information',
                      style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),

              // Emergency Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.2),
                      Colors.red.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'In case of emergency',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Call 10111 or go to your nearest emergency room',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Resource Categories
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return _ResourceCategoryCard(
                      category: _categories[index],
                      onResourceTap: _handleResourceTap,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleResourceTap(Resource resource) async {
    if (resource.isInteractive && resource.route != null) {
      Navigator.pushNamed(context, resource.route!);
    } else if (resource.website != null) {
      final Uri url = Uri.parse(resource.website!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }
}

class _ResourceCategoryCard extends StatelessWidget {
  final ResourceCategory category;
  final Function(Resource) onResourceTap;

  const _ResourceCategoryCard({
    required this.category,
    required this.onResourceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[800]!.withOpacity(0.5),
            Colors.grey[900]!.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(20),
          childrenPadding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 20,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(category.icon, color: category.color, size: 24),
          ),
          title: Text(
            category.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${category.resources.length} resources',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          iconColor: Colors.grey[400],
          collapsedIconColor: Colors.grey[400],
          children:
              category.resources.map((resource) {
                return _ResourceTile(
                  resource: resource,
                  categoryColor: category.color,
                  onTap: () => onResourceTap(resource),
                );
              }).toList(),
        ),
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final Resource resource;
  final Color categoryColor;
  final VoidCallback onTap;

  const _ResourceTile({
    required this.resource,
    required this.categoryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              resource.isEmergency
                  ? Colors.red.withOpacity(0.3)
                  : Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (resource.isEmergency)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '24/7',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (resource.isEmergency) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        resource.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      resource.isInteractive
                          ? Icons.arrow_forward_rounded
                          : Icons.open_in_new_rounded,
                      color: categoryColor,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  resource.description,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (resource.phone != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 16, color: categoryColor),
                      const SizedBox(width: 8),
                      Text(
                        resource.phone!,
                        style: TextStyle(
                          color: categoryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Data Models
class ResourceCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<Resource> resources;

  ResourceCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.resources,
  });
}

class Resource {
  final String title;
  final String description;
  final String? phone;
  final String? website;
  final bool isEmergency;
  final bool isInteractive;
  final String? route;

  Resource({
    required this.title,
    required this.description,
    this.phone,
    this.website,
    this.isEmergency = false,
    this.isInteractive = false,
    this.route,
  });
}
