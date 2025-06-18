-- Pregunta 1. Desglosamos la pregunta en diferentes query, para unirlas al final.
-- Paso 1: obtener el top 5 de productos más vendidos (por cantidad total)
SELECT
    s.ProductID,
    p.ProductName,
    SUM(s.Quantity) AS Cantidad_Total_Vendida_por_Producto
FROM sales s
JOIN products p ON s.ProductID = p.ProductID
GROUP BY s.ProductID, p.ProductName
ORDER BY Cantidad_Total_Vendida_por_Producto DESC
LIMIT 5;

-- 14.016 sec

-- ---------------------------------------------

-- Paso 2: cuál fue el vendedor que más unidades vendió de cada uno?
SELECT
	s.ProductID,
    s.SalesPersonID,
    SUM(s.Quantity) as Cantidad_Total,
    CONCAT(e.FirstName, ' ', e.LastName) AS Nombre_Vendedor
FROM
	sales s
JOIN
	employees e
ON
	s.SalesPersonID = e.EmployeeID
GROUP BY s.ProductID, s.SalesPersonID;

-- 16.812 sec

-- ---------------------------------------------

-- Paso 3: Unimos Paso 1 y Paso 2 en una query que responda a la pregunta de negocio:
-- ¿Hay algún vendedor que aparece más de una vez como el que más vendió un producto? ¿Algunos de estos vendedores representan más del 10% de la ventas de este producto?
WITH top_5_productos_mas_vendidos AS (
    SELECT
        ProductID,
        SUM(Quantity) AS Cantidad_Total
    FROM sales
    GROUP BY ProductID
    ORDER BY Cantidad_Total DESC
    LIMIT 5
),
ventas_por_vendedor_y_producto AS (
    SELECT
        s.ProductID,
        s.SalesPersonID,
        SUM(s.Quantity) AS Cantidad_Total,
        CONCAT(e.FirstName, ' ', e.LastName) AS Nombre_Vendedor
    FROM sales s
    JOIN employees e ON s.SalesPersonID = e.EmployeeID
    JOIN top_5_productos_mas_vendidos tp ON s.ProductID = tp.ProductID
    GROUP BY s.ProductID, s.SalesPersonID
),
top_5_vendedores_por_producto AS (
    SELECT
        vvp.ProductID,
        vvp.SalesPersonID,
        vvp.Nombre_Vendedor,
        vvp.Cantidad_Total
    FROM ventas_por_vendedor_y_producto vvp
    JOIN (
        SELECT
            ProductID,
            MAX(Cantidad_Total) AS Cantidad_Maxima_Vendida
        FROM ventas_por_vendedor_y_producto
        GROUP BY ProductID
    ) t1 ON vvp.ProductID = t1.ProductID AND vvp.Cantidad_Total = t1.Cantidad_Maxima_Vendida
)
SELECT
    p.ProductID,
    pr.ProductName,
    p.Cantidad_Total,
    t.SalesPersonID,
    t.Nombre_Vendedor,
    t.Cantidad_Total AS Cantidad_Maxima_Vendida,
    ROUND(100 * t.Cantidad_Total / p.Cantidad_Total, 2) AS Porcentaje_Participacion,
    CASE
        WHEN ROUND(100 * t.Cantidad_Total / p.Cantidad_Total, 2) > 10 THEN '🔥 Vendedor clave'
        ELSE '—'
    END AS Etiqueta
FROM top_5_productos_mas_vendidos p
JOIN products pr ON pr.ProductID = p.ProductID
JOIN top_5_vendedores_por_producto t ON t.ProductID = p.ProductID
ORDER BY p.Cantidad_Total DESC;

-- 9.047 sec

-- ---------------------------------------------

-- Pregunta 2
-- Paso 1: Entre los 5 productos más vendidos, ¿cuántos clientes únicos compraron cada uno y qué proporción representa sobre el total de clientes?
WITH top_5_productos_mas_vendidos AS (
    SELECT
        ProductID,
        SUM(Quantity) AS Cantidad_Total
    FROM sales
    GROUP BY ProductID
    ORDER BY Cantidad_Total DESC
    LIMIT 5
),
clientes_por_producto AS (
    SELECT
        s.ProductID,
        COUNT(DISTINCT s.CustomerID) AS Clientes_Unicos
    FROM sales s
    JOIN top_5_productos_mas_vendidos t5 ON s.ProductID = t5.ProductID
    GROUP BY s.ProductID
),
total_clientes AS (
    SELECT COUNT(DISTINCT CustomerID) AS total
    FROM sales
)
SELECT
    p.ProductID,
    p.ProductName,
    cpp.Clientes_Unicos,
    tc.total,
    ROUND(cpp.Clientes_Unicos * 100 / tc.total, 2) AS Porcentaje_de_Participacion
FROM clientes_por_producto cpp
JOIN products p ON cpp.ProductID = p.ProductID
CROSS JOIN total_clientes tc
ORDER BY Porcentaje_de_Participacion DESC;

-- 16.031 sec

-- ---------------------------------------------

-- Pregunta 3
-- ¿A qué categorías pertenecen los 5 productos más vendidos y qué proporción representan dentro del total de unidades vendidas de su categoría?

WITH top_5_productos AS (
    SELECT
        s.ProductID,
        p.ProductName,
        p.CategoryID,
        SUM(s.Quantity) AS Total_Unidades_Producto
    FROM sales s
    JOIN products p ON s.ProductID = p.ProductID
    GROUP BY s.ProductID, p.ProductName, p.CategoryID
    ORDER BY Total_Unidades_Producto DESC
    LIMIT 5
),
ventas_por_categoria AS (
    SELECT
        p.CategoryID,
        SUM(s.Quantity) AS Total_Unidades_Categoria
    FROM sales s
    JOIN products p ON s.ProductID = p.ProductID
    GROUP BY p.CategoryID
)
SELECT
    t5.ProductID,
    t5.ProductName,
    c.CategoryName,
    t5.Total_Unidades_Producto,
    vpc.Total_Unidades_Categoria,
    ROUND(100 * t5.Total_Unidades_Producto / vpc.Total_Unidades_Categoria, 2) AS Porcentaje_en_Categoria
FROM top_5_productos t5
JOIN categories c ON t5.CategoryID = c.CategoryID
JOIN ventas_por_categoria vpc ON t5.CategoryID = vpc.CategoryID
ORDER BY Porcentaje_en_Categoria DESC;

-- 26.641 sec

-- ---------------------------------------------

-- Pregunta 4
-- ¿Cuáles son los 10 productos con mayor cantidad de unidades vendidas en todo el catálogo y cuál es su posición dentro de su propia categoría?

WITH ventas_por_producto AS (
    SELECT
        s.ProductID,
        p.ProductName,
        p.CategoryID,
        c.CategoryName,
        SUM(s.Quantity) AS Cantidad_Total_Vendida_Por_Producto
    FROM sales s
    JOIN products p ON s.ProductID = p.ProductID
    JOIN categories c ON p.CategoryID = c.CategoryID
    GROUP BY s.ProductID, p.ProductName, p.CategoryID, c.CategoryName
),
ranking_por_categoria AS (
    SELECT *,
           RANK() OVER (PARTITION BY CategoryID ORDER BY Cantidad_Total_Vendida_Por_Producto DESC) AS Posición_en_Ranking_por_Categoría
    FROM ventas_por_producto
),
top_10_catalogo AS (
    SELECT *
    FROM ranking_por_categoria
    ORDER BY Cantidad_Total_Vendida_Por_Producto DESC
    LIMIT 10
)
SELECT
    ProductID,
    ProductName,
    CategoryName,
    Cantidad_Total_Vendida_Por_Producto,
    Posición_en_Ranking_por_Categoría
FROM top_10_catalogo
ORDER BY Cantidad_Total_Vendida_Por_Producto DESC;

-- 21.078 sec
