/*
import 'package:flutter/material.dart';

class UserListing extends StatefulWidget {
  const UserListing({super.key});

  @override
  State<UserListing> createState() => _UserListingState();
}

class _UserListingState extends State<UserListing> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // List title
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Text(
            '${selectedStatus} Lists',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // List content
        Expanded(
          child: buildUserList(),
        ),

        // Pagination
        buildPagination(),
      ],
    );
  }
  Widget buildUserList() {
    if (_isLoading && _usersList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_usersList.isEmpty) {
      return Center(
        child: Text(
          'No ${selectedStatus.toLowerCase()} users found',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _usersList.length,
      itemBuilder: (context, index) {
        final item = _usersList[index];

        // Calculate sequential serial number
        int serialNumber = (_currentPage * 10) + index + 1;

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                // Serial Number Column
                SizedBox(
                  width: 40,
                  child: Text(
                    '$serialNumber',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                // Name Column
                Expanded(
                  flex: 2,
                  child: Text(
                    item['name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),

                // Organization Column
                Expanded(
                  flex: 3,
                  child: Text(
                    item['organisationName'] ?? 'N/A',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),

                // Status Column
                SizedBox(
                  width: 100,
                  child: buildStatusIndicator(
                      item['status'] ?? 'Pending', item['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
*/
