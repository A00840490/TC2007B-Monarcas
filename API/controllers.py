import database as db

def get_dashboard_kpis():
    try:
        data = db.get_kpis()

        return {
            'dineroDisponible': float(data.get('dineroDisponible', 0)),
            'dineroPrometido': float(data.get('dineroPrometido', 0)),
            'donantesActivos': int(data.get('donantesActivos', 0)),
            'donantesEnRiesgo': int(data.get('donantesEnRiesgo', 0)),
        }
    except Exception as e:
        print(f"Error en get_dashboard_kpis: {e}")
        return {
            'dineroDisponible': 0,
            'dineroPrometido': 0,
            'donantesActivos': 0,
            'donantesEnRiesgo': 0,
        }

def get_donaciones_por_mes():
    try:
        data = db.get_donaciones_meses()
        
        resultado = []
        for item in data:
            resultado.append({
                'id': int(item.get('id', 0)),
                'mes': str(item.get('mes', '')).strip(),
                'monto': int(item.get('monto', 0))
            })
            
        return resultado
    except Exception as e:
        print(f"Error en get_donaciones_por_mes: {e}")
        return []