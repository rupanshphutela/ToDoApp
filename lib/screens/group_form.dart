import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app/models/group.dart';
import 'package:to_do_app/providers/tasks_data_store_provider.dart';

class GroupForm extends StatelessWidget {
  GroupForm({super.key, required this.title, required this.ownerId});
  final String title;
  final int ownerId;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _groupController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskDataStoreProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Form(
            key: _formKey,
            child: TextFormField(
              key: const ValueKey("groupName"),
              maxLines: 1,
              maxLength: 20,
              controller: _groupController,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              decoration: const InputDecoration(
                hintText: 'Enter Group Name',
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                if (provider
                    .groups()
                    .any((element) => element.groupName == value)) {
                  return 'Please enter a distinct non-existing group name';
                }
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(
                (MediaQuery.of(context).size.width).toDouble() * 0.07),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  key: const ValueKey("createGroupForm"),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      provider.addGroup(Group(
                          groupName: _groupController.text,
                          creatorId: ownerId,
                          id: UniqueKey().hashCode));
                      context.pop();
                    }
                  },
                  child: const Text('SAVE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
