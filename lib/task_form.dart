import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:to_do_app/task.dart';
import 'package:to_do_app/tasks_page.dart';

const List<String> status = ['open', 'in progress', 'complete'];

class TaskForm extends StatefulWidget {
  final List<Task> tasks;
  final String title;
  // final Function onComplete;

  const TaskForm(
      {super.key,
      required this.tasks,
      required this.title}); //, required this.onComplete});

  @override
  State<StatefulWidget> createState() => _TaskForm();
}

class _TaskForm extends State<TaskForm> {
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
    _statusController.text = status.first;
  }

  _onSubmit() {
    if (_formKey.currentState!.validate()) {
      if (widget.tasks.isEmpty) {
        List<Task> initialList = List<Task>.generate(
          1,
          (index) => Task(
              taskTitle: _titleController.text,
              description: _descriptionController.text,
              status: _statusController.text,
              lastUpdate: DateTime.now()),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  TasksPage(tasks: initialList, title: widget.title)),
        );
      } else {
        widget.tasks.insert(
            0,
            Task(
                taskTitle: _titleController.text,
                description: _descriptionController.text,
                status: _statusController.text,
                lastUpdate: DateTime.now()));

        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  TasksPage(tasks: widget.tasks, title: widget.title)),
        );
      }
      _formKey.currentState!.reset();
      // widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} - Form'), //value from main widget
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
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
                      maxLines: 1,
                      maxLength: 20,
                      controller: _titleController,
                      inputFormatters: [LengthLimitingTextInputFormatter(20)],
                      decoration: const InputDecoration(
                        hintText: 'Enter Task Title',
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      maxLines: 4,
                      maxLength: 50,
                      controller: _descriptionController,
                      inputFormatters: [LengthLimitingTextInputFormatter(50)],
                      decoration: const InputDecoration(
                        hintText: 'Enter Task Description',
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField(
                      value: _statusController.text,
                      decoration: const InputDecoration(
                        hintText: 'Please select task status',
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'No value selected';
                        }
                        return null;
                      },
                      items: status
                          .map(((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              )))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _statusController.text = value as String;
                        });
                      },
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
                OutlinedButton(
                  onPressed:
                      _onSubmit, //???? Right now, I do the same thing as Save button but it'll change in later assignments
                  child: const Text('CLEAR'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
