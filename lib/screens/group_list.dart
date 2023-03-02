import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app/models/group.dart';
import 'package:to_do_app/models/user_group.dart';

import 'package:to_do_app/utils/routes.dart';
import 'package:to_do_app/models/task.dart';

import 'package:to_do_app/providers/tasks_data_store_provider.dart';

class GroupList extends StatelessWidget {
  const GroupList({super.key, required this.title, required this.ownerId});
  final String title;
  final int ownerId;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskDataStoreProvider>(context);
    List<Group> groups = provider.sharedDataStore.groups;
    List<String>? userGroupNames = provider.personalDataStore.userGroupNames;

    if (groups.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          physics: const ScrollPhysics(),
          child: Column(
            children: [
              Center(
                child: ListView.builder(
                  key: const ValueKey("GroupListKey"),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xff764abc),
                      ),
                      title: Text(
                        groups[index].groupName,
                        key: ValueKey("Group $index Name"),
                        style: const TextStyle(fontSize: 20),
                      ),
                      subtitle: Text('Group ID: ${groups[index].id}'),
                      trailing: Switch(
                        // This bool value toggles the switch.
                        value: userGroupNames.contains(groups[index].groupName)
                            ? true
                            : false,
                        activeColor: Colors.teal,
                        onChanged: (bool value) {
                          if (value == true) {
                            if (!userGroupNames
                                .contains(groups[index].groupName)) {
                              provider.addGroupToUserGroups(UserGroup(
                                  userId: ownerId,
                                  groupId:
                                      int.parse(groups[index].id.toString()),
                                  groupName: groups[index].groupName));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Group already exists in the user groups')));
                            }
                          } else {
                            provider.removeGroupFromUserGroups(
                                int.parse(groups[index].id.toString()),
                                ownerId);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.push('/group?ownerId=$ownerId');
          },
          child: const Icon(Icons.add),
        ),
      );
    } else {
      provider.sharedDataStore.getAllGroups();
      provider.personalDataStore.getUserGroups(ownerId);

      return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
              ),
            ],
          ),
        ),
        body: const SafeArea(
          child: Center(
            child: Text(
              "Nothing here!!\n\nPress Add + button\nbelow to create a group",
              style: TextStyle(color: Colors.black, fontSize: 24),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.push('/group?ownerId=$ownerId');
          },
          child: const Icon(Icons.add),
        ),
      );
    }
  }
}
