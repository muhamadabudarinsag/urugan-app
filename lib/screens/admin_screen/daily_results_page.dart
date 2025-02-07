import 'package:flutter/material.dart';

class DailyResultsPage extends StatelessWidget {
  const DailyResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Results'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Results Summary',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Placeholder for results list
            Expanded(
              child: ListView.builder(
                itemCount: 10, // Placeholder count, replace with actual results count
                itemBuilder: (context, index) {
                  return _buildResultCard(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(int index) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 8,
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.3),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          title: Text(
            'Result ${index + 1}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Details for result ${index + 1}',
            style: TextStyle(color: Colors.grey[700]),
          ),
          trailing: Icon(Icons.arrow_forward, color: Colors.blueAccent),
        ),
      ),
    );
  }
}
