import 'package:flutter/material.dart';

import 'package:to_do_app/task.dart';
import 'package:to_do_app/tasks_page.dart';

const List<String> status = ['open', 'in progress', 'complete'];
var _initValue = "";

class TaskDetails extends StatefulWidget {
  final List<Task> tasks;
  final String title;
  final int selectedTaskIndex;
  // final Function onComplete;

  const TaskDetails(
      {super.key,
      required this.tasks,
      required this.selectedTaskIndex,
      required this.title}); //, required this.onComplete});

  @override
  State<StatefulWidget> createState() => _TaskDetails();
}

class _TaskDetails extends State<TaskDetails> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _statusController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _statusController.text = widget.tasks[widget.selectedTaskIndex].status;
  }

  _onSubmit() {
    if (_formKey.currentState!.validate()) {
      print(widget.tasks[widget.selectedTaskIndex].status);
      widget.tasks[widget.selectedTaskIndex].status = _statusController.text;
      widget.tasks[widget.selectedTaskIndex].lastUpdate = DateTime.now();
      widget.tasks.sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                TasksPage(tasks: widget.tasks, title: widget.title)),
      );
      _formKey.currentState!.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} - Task Details'), //value from main widget
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      initialValue:
                          widget.tasks[widget.selectedTaskIndex].taskTitle,
                      readOnly: true,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    TextFormField(
                      initialValue:
                          widget.tasks[widget.selectedTaskIndex].description,
                      readOnly: true,
                      maxLines: null,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    DropdownButtonFormField(
                      isExpanded: true,
                      autofocus: true,
                      value: _statusController.text,
                      isDense: false,
                      onChanged: (value) {
                        setState(() {
                          _statusController.text = value as String;
                        });
                      },
                      items: status.map((statusValue) {
                        return DropdownMenuItem(
                          value: statusValue,
                          child: Text(statusValue),
                        );
                      }).toList(),
                    ),
                    Text(
                      'Last updated: ${widget.tasks[widget.selectedTaskIndex].lastUpdate.toString().substring(0, 19)}',
                    ),
                  ],
                )),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _onSubmit,
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
