import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import 'package:assets_manager_app/screens/details/asset_details_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _selectedFilters = [];
  bool _isAdvancedSearch = false;
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  double _minPrice = 0;
  double _maxPrice = double.infinity;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Furniture',
    'Vehicles',
    'Tools',
    'Other'
  ];

  final List<String> _statuses = [
    'All',
    'Available',
    'In Use',
    'Under Maintenance',
    'Retired'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search assets...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isAdvancedSearch ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _isAdvancedSearch = !_isAdvancedSearch;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isAdvancedSearch) _buildAdvancedSearchFilters(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final assets = snapshot.data!.docs
                    .map((doc) => Asset.fromFirestore(doc))
                    .where((asset) => _filterAsset(asset))
                    .toList();

                if (assets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No assets found'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final asset = assets[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(_getCategoryIcon(asset.category)),
                        title: Text(asset.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category: ${asset.category}'),
                            Text('Status: ${asset.status}'),
                            Text('Location: ${asset.location}'),
                          ],
                        ),
                        trailing: Text(
                          '\$${asset.purchasePrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AssetDetailsScreen(asset: asset),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSearchFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: _statuses.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Min Price',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _minPrice = double.tryParse(value) ?? 0;
                    });
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Max Price',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _maxPrice = double.tryParse(value) ?? double.infinity;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    Query query = _firestore.collection('assets');
    
    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }
    
    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    return query.snapshots();
  }

  bool _filterAsset(Asset asset) {
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      if (!asset.name.toLowerCase().contains(query) &&
          !asset.description.toLowerCase().contains(query) &&
          !asset.location.toLowerCase().contains(query)) {
        return false;
      }
    }

    if (asset.purchasePrice < _minPrice || asset.purchasePrice > _maxPrice) {
      return false;
    }

    return true;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.computer;
      case 'furniture':
        return Icons.chair;
      case 'vehicles':
        return Icons.directions_car;
      case 'tools':
        return Icons.build;
      default:
        return Icons.category;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 