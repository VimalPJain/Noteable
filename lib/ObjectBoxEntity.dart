import 'package:objectbox/objectbox.dart';

//Added new entity with a title and description needed for creation of Note
@Entity()
class Note {
  @Id()
  int id = 0;

  late String title;
  late String description;

  Note({this.id = 0, required this.title, required this.description});
}
