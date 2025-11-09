/// This is Model class. Using this model class, you can add the list of data with title and its selection.
class SelectedListItem {
  bool? isSelected;
  String name;
  dynamic? value;
  String? idvalue;

  SelectedListItem({
    required this.name,
    this.value,
    this.idvalue,
    this.isSelected,
  });
}
