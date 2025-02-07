// Update the GridView.count children array in the build method to include the new menu item
_buildInfoCard(
  title: 'Supplier & Bank',
  icon: Icons.business,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierBankMenuPage(),
      ),
    );
  },
),
