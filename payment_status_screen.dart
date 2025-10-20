import 'package:flutter/material.dart';
import '../db/database_helper1.dart';

class PaymentStatusScreen extends StatefulWidget {
  final String shopkeeper;

  PaymentStatusScreen({required this.shopkeeper});

  @override
  _PaymentStatusScreenState createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  final db = DatabaseHelper();
  List<Map<String, dynamic>> payments = [];
  double totalPaid = 0;
  double totalAmount = 0;
  double remaining = 0;

  final skyBlue = Colors.lightBlue[400];
  final lightBlue = Colors.lightBlue[200];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    await _calculateTotalAmount();
    await _loadPayments();
  }

  Future<void> _calculateTotalAmount() async {
    final salesList = await db.getSalesByShopkeeper(widget.shopkeeper);
    double total = 0;
    for (var s in salesList) {
      total += s['amount'] ?? 0.0;
    }
    setState(() {
      totalAmount = total;
      remaining = totalAmount - totalPaid;
    });
  }

  Future<void> _loadPayments() async {
    final paymentList = await db.getPaymentsByShopkeeper(widget.shopkeeper);

    double paid = 0;
    for (var p in paymentList) {
      paid += (p['amount'] ?? 0.0);
    }

    setState(() {
      payments = paymentList;
      totalPaid = paid;
      remaining = totalAmount - totalPaid;
    });
  }

  // ✅ Add Payment Dialog
  Future<void> _addPayment() async {
    double amount = 0;
    String status = "Unpaid";
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.lightBlue.shade200, width: 2),
          ),
          title: Text(
            "${widget.shopkeeper} Payment",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount",
                  labelStyle: TextStyle(color: Colors.black),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightBlue.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.lightBlue.shade400, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: TextStyle(color: Colors.black),
                onChanged: (val) => amount = double.tryParse(val) ?? 0,
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.lightBlue.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: status,
                  dropdownColor: Colors.white,
                  underline: SizedBox(),
                  isExpanded: true,
                  items: ["Unpaid", "Partial", "Paid"]
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: TextStyle(
                                color:
                                    (s == "Paid") ? Colors.green : Colors.red,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setStateDialog(() => status = val);
                  },
                ),
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Text(
                    "Date: ${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Spacer(),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.lightBlue.shade200),
                      foregroundColor: Colors.black,
                    ),
                    child: Text("Select"),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme:
                                ColorScheme.light(primary: skyBlue!),
                          ),
                          child: child!,
                        ),
                      );
                      if (date != null)
                        setStateDialog(() => selectedDate = date);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel", style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: lightBlue,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Save",
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await db.insertPayment(
        widget.shopkeeper,
        amount,
        status,
        date: selectedDate.toIso8601String(),
        profit: 0.0,
      );
      await _refreshData();
    }
  }

  // ✅ Add Profit Dialog
  Future<void> _addProfit() async {
    double amount = 0;
    String status = "Unpaid";
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.lightBlue.shade200, width: 2),
          ),
          title: Text(
            "${widget.shopkeeper} Profit",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Profit Amount",
                  labelStyle: TextStyle(color: Colors.black),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.lightBlue.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.lightBlue.shade400, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: TextStyle(color: Colors.black),
                onChanged: (val) => amount = double.tryParse(val) ?? 0,
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.lightBlue.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: status,
                  dropdownColor: Colors.white,
                  underline: SizedBox(),
                  isExpanded: true,
                  items: ["Unpaid", "Partial", "Paid"]
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: TextStyle(
                                color:
                                    (s == "Paid") ? Colors.green : Colors.red,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setStateDialog(() => status = val);
                  },
                ),
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Text(
                    "Date: ${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Spacer(),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.lightBlue.shade200),
                      foregroundColor: Colors.black,
                    ),
                    child: Text("Select"),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme:
                                ColorScheme.light(primary: skyBlue!),
                          ),
                          child: child!,
                        ),
                      );
                      if (date != null)
                        setStateDialog(() => selectedDate = date);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel", style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: lightBlue,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Save",
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await db.insertPayment(
        widget.shopkeeper,
        0.0,
        status,
        date: selectedDate.toIso8601String(),
        profit: amount,
      );
      await _refreshData();
    }
  }

  // ✅ Add Message Dialog
  Future<void> _addMessage() async {
    String message = "";

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.lightBlue.shade200, width: 2),
        ),
        title: Text(
          "${widget.shopkeeper} Message",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: "Enter Message",
            labelStyle: TextStyle(color: Colors.black),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlue.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: Colors.lightBlue.shade400, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: TextStyle(color: Colors.black),
          onChanged: (val) => message = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: lightBlue,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Send",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (result == true && message.isNotEmpty) {
      await db.insertPayment(
        widget.shopkeeper,
        0.0,
        "Message",
        date: DateTime.now().toIso8601String(),
        profit: 0.0,
        message: message,
      );
      await _refreshData();
    }
  }

  Future<void> _deletePayment(int id) async {
    await db.deletePayment(id);
    await _refreshData();
  }

  Color _statusColor(String status) {
    if (status == "Paid") return Colors.green;
    if (status == "Message") return Colors.blueGrey;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.shopkeeper} Payments",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: skyBlue,
        actions: [
          IconButton(
            icon: Icon(Icons.payment, color: Colors.black),
            tooltip: "Add Payment",
            onPressed: _addPayment,
          ),
          IconButton(
            icon: Icon(Icons.attach_money, color: Colors.black),
            tooltip: "Add Profit",
            onPressed: _addProfit,
          ),
          IconButton(
            icon: Icon(Icons.message, color: Colors.black),
            tooltip: "Add Message",
            onPressed: _addMessage,
          ),
        ],
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: payments.isEmpty
          ? Center(
              child: Text("No payments recorded yet",
                  style: TextStyle(color: Colors.black)),
            )
          : ListView.builder(
              itemCount: payments.length,
              itemBuilder: (_, index) {
                final p = payments[index];
                final isLatest = index == payments.length - 1;

                return Card(
                  color: isLatest ? Colors.green[50] : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.lightBlue.shade100),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: Icon(
                      p['status'] == "Message"
                          ? Icons.message
                          : Icons.payment,
                      color: isLatest ? Colors.green : Colors.blue,
                    ),
                    title: Text(
                      p['status'] == "Message"
                          ? "Message"
                          : (p['profit'] != null && p['profit'] > 0
                              ? "Profit: Rs.${p['profit']}"
                              : "Rs.${p['amount']}"),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    subtitle: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Status: ",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          TextSpan(
                              text: "${p['status']} ",
                              style:
                                  TextStyle(color: _statusColor(p['status']))),
                          TextSpan(
                            text: "| Date: ",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          TextSpan(
                            text: "${p['date'].toString().split('T')[0]}",
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletePayment(p['id']),
                    ),
                    // ✅ Navigate to detail page for messages
                    onTap: () {
                      if (p['status'] == "Message" &&
                          p['message'] != null &&
                          p['message'].toString().isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MessageDetailScreen(
                              id: p['id'],
                              message: p['message'],
                              onUpdated: _refreshData,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ✅ New Screen for Message Details + Edit option
class MessageDetailScreen extends StatelessWidget {
  final int id;
  final String message;
  final Future<void> Function() onUpdated;

  MessageDetailScreen(
      {required this.id, required this.message, required this.onUpdated});

  final db = DatabaseHelper();

  Future<void> _editMessage(BuildContext context, String oldMessage) async {
    String newMessage = oldMessage;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit Message", style: TextStyle(color: Colors.black)),
        content: TextField(
          controller: TextEditingController(text: oldMessage),
          maxLines: 3,
          onChanged: (val) => newMessage = val,
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlue.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlue.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlue.shade400, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            labelText: "Message",
            labelStyle: TextStyle(color: Colors.black),
          ),
        ),
        actions: [
          TextButton(
            child: Text("Cancel", style: TextStyle(color: Colors.black)),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: Text("Save",
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue[400],
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true && newMessage.isNotEmpty) {
      await db.updatePaymentMessage(id, newMessage);
      await onUpdated();
      Navigator.pop(context); // back to PaymentStatusScreen after save
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Message Detail", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.lightBlue[400],
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.black),
            onPressed: () => _editMessage(context, message),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.lightBlue.shade100),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}
