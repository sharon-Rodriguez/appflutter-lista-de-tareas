import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de tareas',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: TodoListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// PANTALLA PRINCIPAL
class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final List<String> _tasks = [];
  final List<bool> _taskDone = [];
  final TextEditingController _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _loadTask();
  }

  @override
  void dispose() {
    _taskController.dispose();

    super.dispose();
  }

  //LOGICA DE LA APLICACION

  //se crea metodo para agregar las tareas
  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add(_taskController.text);
        _taskDone.add(false);
      });
      _taskController.clear();
      _saveTask(); //metodo para guardar en el dispositivo
    }
  }

  //metodo para marcar o desmarcar tarea
  void _toggleTask(int index) {
    setState(() {
      _taskDone[index] = !_taskDone[index];
    });
    _saveTask();
  }

  //metodo para eliminar tarea
  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
      _taskDone.removeAt(index);
    });
    _saveTask();
  }

  //Metodos (asincrinos)

  //metodo para guardar tareas
  Future<void> _saveTask() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList('task', _tasks);

    List<String> taskDoneString = _taskDone
        .map((isDone) => isDone.toString())
        .toList();

    await prefs.setStringList('taskDone', taskDoneString);
  }

  //metodo para cargar las tareas
  Future<void> _loadTask() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> loadedTask = prefs.getStringList('task') ?? [];

    List<String> loadedTaskDone = prefs.getStringList('taskDone') ?? [];

    setState(() {
      _tasks.addAll(loadedTask);
      _taskDone.addAll(
        loadedTaskDone.map((bol)=> bol == 'true' ? true : false),
      );
    });
  }
//Metodo para mostrar un espacio para añadir tareas (pop-up)

void _showAddDialog(){
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Nueva Tarea'),
        content: TextField(
          controller: _taskController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Escribe tu tarea aquí...'),
        ),
      //botones para el dialogo
        actions: [

          //para CANCELAR
          TextButton(
            child: Text('Cancelar'),
            onPressed:() {
              _taskController.clear();
              Navigator.of(context).pop();
            },
          ),

          //para GUARDAR
          TextButton(
            child: Text('Guardar'),
            onPressed: (){
              _addTask();
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

//Metodo de construccion UI



}
