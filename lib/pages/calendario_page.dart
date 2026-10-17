import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Mapa de eventos por fecha (MOCK para maquetación)
  final Map<DateTime, List<String>> _eventosMock = {
    DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day): [
      'Leche (Por caducar)',
      'Jamon (Caducado)'
    ],
    DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day + 2): [
      'Pan de caja (Por caducar)'
    ],
  };

  List<String> _getEventosDelDia(DateTime day) {
    final key = DateTime.utc(day.year, day.month, day.day);
    return _eventosMock[key] ?? [];
  }

  void _mostrarModalCompleto(BuildContext context, DateTime fecha, List<String> eventos) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text('Artículos para ${fecha.day}/${fecha.month}/${fecha.year}'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: eventos.isEmpty
                ? const Center(child: Text('No hay alertas para este día'))
                : ListView.builder(
                    itemCount: eventos.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.warning, color: Colors.amber),
                        title: Text(eventos[index]),
                        subtitle: const Text('Revisar estado en alacena'),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _getEventosDelDia,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            final eventos = _getEventosDelDia(selectedDay);
            _mostrarModalCompleto(context, selectedDay, eventos);
          },
          calendarStyle: const CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}