# Herramienta de Diseño de Economía de Puntos

**Para**: Equipo de Negocio / Product Managers
**Propósito**: Diseñar valores de puntos balanceados para sistemas de gamificación

---

## ¿Qué hace esta herramienta?

Te ayuda a responder:
1. **¿Cuántos puntos dar a cada acción?** (comentarios, compras, referidos, etc.)
2. **¿Está balanceado?** (detecta formas de "hacer trampa" en el sistema)
3. **¿Qué van a hacer los usuarios?** (simula comportamiento para estos incentivos)

## Cómo Usar

### Opción 1: Pedir a Claude Code (Recomendado)

Si trabajas con el equipo técnico, simplemente pide:

```
"Necesito diseñar los puntos para nuestro challenge.
Usa el skill designing-points-economy para crear la economía."
```

Claude te hará preguntas sobre:
- Objetivos de negocio (engagement vs revenue vs comunidad)
- Datos comerciales (CAC, ticket promedio, márgenes)
- Restricciones operativas (capacidad de validar manualmente)

Luego generará un **Excel completo** con:
- 3 escenarios de puntos (relativo, económico, basado en objetivos)
- Validación de gaming
- Simulación de comportamiento usuario
- Comparación de escenarios

### Opción 2: Ejecutar Script Directamente (Si tienes Python)

```bash
# Instalar dependencias
pip install pandas openpyxl

# Ejecutar calculadora
python points_economy_calculator.py

# Output: zona_condores_points_economy.xlsx
```

El script tiene un ejemplo pre-cargado con las acciones actuales de Zona Cóndores. Puedes editar los valores en el código para tu caso específico.

---

## Metodología: Los 4 Ejes de Evaluación

Cada acción se evalúa en 4 dimensiones (escala 1-10):

### **C - Community/Engagement**
¿Cuánto alcance/visibilidad genera?
- 1-3: Privado (poll, perfil)
- 4-6: Semi-público (comment)
- 7-10: Alto alcance (post con hashtag, story)

### **E - Quality/Enforceability**
¿Qué tan fácil es validar calidad?
- 1-3: Fácil de spamear (comments genéricos)
- 4-6: Validación moderada (largo mínimo, keywords)
- 7-10: Inherentemente verificable (compras, referidos verificados)

### **B - Business Value**
¿Genera revenue directo o indirecto?
- 1-3: Sin revenue (likes, follows)
- 4-6: Conversión indirecta (engagement → futura compra)
- 7-10: Revenue directo (compra, referido que compra)

### **F - Future Value (LTV)**
¿Es indicador de usuarios de alto valor?
- 1-3: Acción única, sin señal futura
- 4-6: Hábito formador (engagement semanal)
- 7-10: Alto LTV (referido, compra premium)

---

## 3 Modos de Calcular Puntos

### **Modo A: Escala Relativa** (más simple)
- Define acción base: "comment = 10 puntos"
- Asigna pesos a dimensiones: C=20%, E=20%, B=35%, F=25%
- Escala todo proporcionalmente

**Cuándo usar**: No tienes datos económicos precisos, confías en evaluación cualitativa

### **Modo B: Anclaje Económico** (más defendible)
- Calcula valor CLP de cada acción (revenue, CAC ahorrado)
- Define conversión: "1 punto = $X CLP de valor"
- Ajusta con multiplicadores estratégicos (2x para acciones prioritarias)

**Cuándo usar**: Tienes datos de CAC, LTV, márgenes. Necesitas justificar a CFO/CEO.

### **Modo C: Basado en Objetivos** (goal-oriented)
- Input: "Queremos 500 posts/mes, 50 compras/mes, 20 referidos/mes"
- Calcula presupuesto de puntos mensual
- Distribuye para lograr esos volúmenes

**Cuándo usar**: Tienes metas claras de volumen por tipo de acción

---

## Output del Excel

### **Sheet 1: Evaluation**
Tabla editable con las 4 dimensiones (C, E, B, F) para cada acción. Aquí puedes ajustar los scores manualmente.

### **Sheet 2: Recommendations**
Comparación lado a lado de los 3 modos:
```
Acción              | Modo A | Modo B | Modo C | Recomendado
--------------------|--------|--------|--------|-------------
ig_comment          |   10   |    8   |   12   |     10
ig_post_hashtag     |   45   |   35   |   50   |     40
purchase            |  150   |  200   |  100   |    150
referral            |  180   |  250   |  200   |    200
```

### **Sheet 3: Gaming Risks**
Detecta vulnerabilidades automáticamente:
- ⚠️ "Comentarios (10pts/2min) más eficiente que compras → usuarios solo comentarán"
- ⚠️ "Sin límite diario en comments → farming posible (500pts/día fácil)"
- ⚠️ "Compras tienen alto valor de negocio (B=10) pero puntos por debajo del promedio"

### **Sheet 4: User Behavior Sim**
Simula usuario "racional" que maximiza puntos con 30min/día:
```
Con config actual, estrategia óptima:
1. 15 comentarios (150pts en 30min)
2. NUNCA compra ni hace posts

Recomendación: Reducir comment a 5pts O agregar cap de 5/día
```

---

## Ejemplo Real: Zona Cóndores

**Acciones evaluadas:**

| Acción | C | E | B | F | Tiempo | Dificultad |
|--------|---|---|---|---|--------|------------|
| ig_comment | 5 | 3 | 2 | 4 | 2min | Fácil (2) |
| ig_post_hashtag | 8 | 6 | 5 | 6 | 15min | Media (6) |
| purchase | 2 | 10 | 10 | 8 | 30min | Media (5) |
| referral | 6 | 9 | 7 | 10 | 60min | Difícil (8) |
| poll_response | 2 | 8 | 1 | 2 | 1min | Muy fácil (1) |
| trivia_perfect | 3 | 9 | 3 | 5 | 5min | Difícil (7) |

**Resultados Modo A (pesos default):**
- ig_comment: **10 pts** (baseline)
- ig_post_hashtag: **42 pts**
- purchase: **136 pts**
- referral: **163 pts**
- poll_response: **8 pts**
- trivia_perfect: **22 pts**

**Gaming detectado:**
- ⚠️ Comments sin cap diario → puede farmear 240 comments (2,400pts) vs 1 compra (136pts)
- **Mitigación**: Reducir a 5pts O agregar límite de 10 comments/día

**Simulación usuario racional (30min/día):**
- Estrategia óptima: 15 comments (150pts) - ignora todo lo demás
- Con mitigación (cap 10/día): Hace 10 comments (50pts) + 1 poll (8pts) + intenta trivia (22pts)

---

## Preguntas Frecuentes

### "¿Por qué no simplemente asignar números que 'se sientan bien'?"
Porque los usuarios SIEMPRE encuentran la forma más fácil de ganar puntos. Sin validación, terminas con:
- Spam de comments genéricos
- Cero compras (porque comments dan más puntos/minuto)
- Usuarios molestos cuando tienes que reducir puntos post-launch

### "¿Qué modo es mejor?"
Depende de tu situación:
- **Startup/MVP**: Modo A (simple, rápido)
- **Presentando a C-level**: Modo B (datos económicos)
- **Tienes KPIs claros**: Modo C (orientado a objetivos)

**Pro tip**: Ejecuta los 3, compara, y presenta al equipo para decidir juntos.

### "¿Puedo cambiar puntos después del launch?"
Técnicamente sí, pero cambia los puntos que los usuarios ya ganaron destruye confianza. Es MUCHO mejor invertir 1-2 horas en el framework antes de lanzar que tener que ajustar después.

### "¿Cómo sé si mis evaluaciones (C, E, B, F) son correctas?"
No hay valores "correctos" objetivamente - son decisiones de negocio. El framework te ayuda a ser **consistente** y a **detectar consecuencias** de esas decisiones.

Si dudas:
1. Evalúa con 2-3 personas del equipo independientemente
2. Comparen y discutan diferencias
3. Lleguen a consenso
4. Ejecuten los 3 modos y validen gaming

---

## Contacto

**Dudas técnicas**: Equipo de desarrollo
**Dudas de negocio/metodología**: [Product Manager / Growth Lead]

**Versión**: 1.0 (Enero 2026)
