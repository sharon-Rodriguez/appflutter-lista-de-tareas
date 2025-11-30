import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:todo_app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async { 
  
  WidgetsFlutterBinding.ensureInitialized(); 

  await Firebase.initializeApp(
   options: DefaultFirebaseOptions.currentPlatform,
  );
  
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
  final List<String> _taskIDs = [];
  final TextEditingController _taskController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    String newTask = _taskController.text; // Capturamos el texto antes de limpiar

    // setState(() {
    //   _tasks.add(newTask); 
    //   _taskDone.add(false);
    // });

    _taskController.clear();
    _saveTask(newTask, false); 
  }
}

  //metodo para marcar o desmarcar tarea
  void _toggleTask(int index) {
  // Obtenemos el ID del documento de la tarea que se está marcando
  String taskId = _taskIDs[index];
  bool newState = !_taskDone[index]; // El nuevo estado

  // 1. Actualizar la interfaz localmente (UI)
  setState(() {
    _taskDone[index] = newState;
  });

  // Actualizar en Firestore
  _updateTaskStatus(taskId, newState); // Llamamos a la función de actualización de Firestore
}

//  NUEVA FUNCIÓN PARA ACTUALIZAR EN FIRESTORE
Future<void> _updateTaskStatus(String taskId, bool newState) async {
  try {
    await FirebaseFirestore.instance.collection('tareas').doc(taskId).update({
      'completada': newState,
    });
  } catch (e) {
    print('Error al actualizar la tarea en Firestore: $e');
  }
}

  //metodo para eliminar tarea
  void _removeTask(int index) {
  String taskId = _taskIDs[index]; // Obtenemos el ID antes de eliminar
  
  // 1. Eliminar de Firestore
  _deleteTaskFromFirestore(taskId);

  // 2. Actualizar las listas locales (UI)
  setState(() {
    _tasks.removeAt(index);
    _taskDone.removeAt(index);
    _taskIDs.removeAt(index); // NO OLVIDES ELIMINAR EL ID LOCALMENTE
  });
}

//  NUEVA FUNCIÓN PARA ELIMINAR EN FIRESTORE
Future<void> _deleteTaskFromFirestore(String taskId) async {
  try {
    await FirebaseFirestore.instance.collection('tareas').doc(taskId).delete();
  } catch (e) {
    print('Error al eliminar la tarea de Firestore: $e');
  }
}

  //Metodos (asincrinos)

  //metodo para guardar tareas
  Future<void> _saveTask(String taskTitle, bool isDone) async {
  CollectionReference tareasCollection = _firestore.collection('tareas');

  try {
    // 1. Guardar y capturar el ID de la base de datos
    DocumentReference docRef = await tareasCollection.add({
      'titulo': taskTitle,       
      'completada': isDone,      
      'timestamp': FieldValue.serverTimestamp(), 
    });

    // 2. ÚNICO setState para actualizar la UI y las listas locales con el ID
    setState(() {
      // Añadir la tarea para que se muestre en la lista
      _tasks.add(taskTitle); 
      _taskDone.add(isDone);
      
      // Añadir el ID para que se pueda eliminar o marcar
      _taskIDs.add(docRef.id); 
    });
    
    print('Tarea "$taskTitle" guardada en Firestore con ID: ${docRef.id}');

  } catch (e) {
    print("Error al guardar la tarea en Firestore: $e");
  }
}

  //metodo para cargar las tareas
  Future<void> _loadTask() async {
  try {
    QuerySnapshot snapshot = await _firestore
        .collection('tareas')
        .orderBy('timestamp', descending: false)
        .get();

    setState(() {
      _tasks.clear();
      _taskDone.clear();
      _taskIDs.clear();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        _tasks.add(data['titulo'] ?? '');
        _taskDone.add(data['completada'] ?? false);
        _taskIDs.add(doc.id);
      }
    });

    print('Se cargaron ${_tasks.length} tareas desde Firebase');
  } catch (e) {
    print('Error al cargar tareas desde Firebase: $e');
  }
}

  

  //Metodo para mostrar un espacio para añadir tareas (pop-up)

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Nueva Tarea'),
          content: TextField(
            controller: _taskController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Escribe tu tarea aquí...',
            ),
          ),
          //botones para el dialogo
          actions: [
            //para CANCELAR
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                _taskController.clear();
                Navigator.of(context).pop();
              },
            ),

            //para GUARDAR
            TextButton(
              child: Text('Guardar'),
              onPressed: () {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        toolbarHeight: 100.0,

        title: const Text(
          'Mi lista de tareas',
          style: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: Key(_tasks[index] + index.toString()),

            onDismissed: (direction) {
              _removeTask(index);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Tarea Eliminada')));
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: Icon(Icons.delete, color: Colors.white),
            ),

            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: ListTile(
                leading: Checkbox(
                  value: _taskDone[index],
                  onChanged: (bool? value) {
                    _toggleTask(index);
                  },
                ),
                title: Text(
                  _tasks[index],

                  style: TextStyle(
                    decoration: _taskDone[index]
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      //Boton flotante de la esquina
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'Añadir Tarea',
        child: const Icon(Icons.add),
      ),

      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Container(height: 8.0),
      ),
    );
  }
}
