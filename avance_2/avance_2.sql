-- 1. Creación de la tabla que recojerá los resultados del Trigger
CREATE TABLE producto_umbral_superado (
    id_registro INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    product_name VARCHAR(255),
    cantidad_total_vendida INT,
    fecha_superado DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 0.734 sec

-- ----------------------------------------------------------------

-- 2. Script del Trigger
DELIMITER $$

CREATE TRIGGER trigger_supera_200k
AFTER INSERT ON sales
FOR EACH ROW
BEGIN
    DECLARE total_vendido INT;
    DECLARE nombre_producto VARCHAR(255);

    -- Cálculo del total vendido del producto después de esta nueva venta
    SELECT SUM(quantity)
    INTO total_vendido
    FROM sales
    WHERE productID = NEW.productID;

    -- Solo continúa si supera las 200k unidades vendidas
    IF total_vendido > 200000 THEN
        -- Verificamos que aún no haya sido registrado este evento para evitar duplicados
        IF NOT EXISTS (
            SELECT 1
            FROM producto_umbral_superado
            WHERE product_id = NEW.productID
        ) THEN
            -- Obtenemos el nombre del producto
            SELECT productName
            INTO nombre_producto
            FROM products
            WHERE productID = NEW.productID;

            -- Insertar en la tabla de monitoreo 'producto_umbral_superado'
            INSERT INTO producto_umbral_superado (
                product_id,
                product_name,
                cantidad_total_vendida
            )
            VALUES (
                NEW.productID,
                nombre_producto,
                total_vendido
            );
        END IF;
    END IF;
END$$

DELIMITER ;

-- 0.313 sec

-- ----------------------------------------------------------------

-- PRUEBA PROPIA DEL TRIGGER:
-- Búsqueda de un producto cerca de umbral para prueba
SELECT
    ProductID,
    SUM(Quantity) AS Total_Actual
FROM sales
GROUP BY ProductID
ORDER BY Total_Actual DESC
LIMIT 10;

-- 6.610 sec

-- Insertando un SalesID de prueba que no existe, para probar el trigger con el ProductID = 179
INSERT INTO sales (
    SalesID,
    SalesPersonID,
    CustomerID,
    ProductID,
    Quantity,
    Discount,
    TotalPrice,
    SalesDate,
    TransactionNumber
)
VALUES (
    9999999,         -- SalesID único manual
    27,
    5100,
    179,
    300,
    0.00,
    0.00,
    NOW(),
    CONCAT('TRX-', UUID())
);

-- 4.110 sec

SELECT *
FROM producto_umbral_superado
WHERE product_id = 179;


-- Insertando un SalesID de prueba que no existe, para probar el trigger con el ProductID = 161
INSERT INTO sales (
    SalesID,
    SalesPersonID,
    CustomerID,
    ProductID,
    Quantity,
    Discount,
    TotalPrice,
    SalesDate,
    TransactionNumber
)
VALUES (
    10000000,        -- SalesID único, diferente del anterior
    28,            
    5101,
    161,
    350,           
    0.00,
    0.00,
    NOW(),
    CONCAT('TRX-', UUID())
);

-- 4.093

SELECT *
FROM producto_umbral_superado
WHERE product_id = 161;

-- ----------------------------------------------------------------

-- 3.
-- a. Registro de una venta sugerida en el avance con una cantidad de 1876 unidades para monitorear y evaluar comportamiento
INSERT INTO sales (
    SalesID,
    SalesPersonID,
    CustomerID,
    ProductID,
    Quantity,
    Discount,
    TotalPrice,
    SalesDate,
    TransactionNumber
)
VALUES (
    10000001,        -- SalesID único 
    9,              -- Vendedor
    84,             -- Cliente
    103,            -- Producto
    1876,           -- Unidades vendidas
    0.00,           -- Sin descuento
    1200.00,        -- Valor total de la operación
    NOW(),          -- Fecha actual
    CONCAT('TRX-', UUID())  -- Identificador de transacción único
);

-- 4.250 SEC

SELECT *
FROM producto_umbral_superado
WHERE product_id = 103;

-- b. Registro de una venta sugerida en el avance con una cantidad de 1200 unidades para monitorear y evaluar comportamiento
INSERT INTO sales (
    SalesID,
    SalesPersonID,
    CustomerID,
    ProductID,
    Quantity,
    Discount,
    TotalPrice,
    SalesDate,
    TransactionNumber
)
VALUES (
    10000002,        -- SalesID único
    9,              -- Vendedor
    84,             -- Cliente
    103,            -- Producto
    1200,           -- Unidades vendidas
    0.00,           -- Sin descuento
    1876.00,        -- Valor total de la operación
    NOW(),          -- Fecha actual
    CONCAT('TRX-', UUID())  -- Identificador de transacción único
);

-- 4.328

SELECT *
FROM producto_umbral_superado
WHERE product_id = 103;

select * 
from sales
where SalesID = 10000002;

-- ----------------------------------------------------------------

-- 4. Consulta original sin índices (versión base para medir performance inicial)
-- a. ¿Hay algún vendedor que aparece más de una vez como el que más vendió un producto? ¿Algunos de estos vendedores representan más del 10% de la ventas de este producto?
WITH ventas_por_vendedor AS (
    SELECT
        s.ProductID,
        s.SalesPersonID,
        SUM(s.Quantity) AS Cantidad_Vendida
    FROM sales s
    GROUP BY s.ProductID, s.SalesPersonID
),
top_5_productos AS (
    SELECT
        ProductID,
        SUM(Cantidad_Vendida) AS Total_Vendido
    FROM ventas_por_vendedor
    GROUP BY ProductID
    ORDER BY Total_Vendido DESC
    LIMIT 5
),
ranking_vendedores AS (
    SELECT
        v.ProductID,
        v.SalesPersonID,
        v.Cantidad_Vendida,
        p.ProductName,
        e.FirstName,
        e.LastName,
        t.Total_Vendido,
        RANK() OVER (PARTITION BY v.ProductID ORDER BY v.Cantidad_Vendida DESC) AS Posicion
    FROM ventas_por_vendedor v
    JOIN top_5_productos t ON v.ProductID = t.ProductID
    JOIN products p ON p.ProductID = v.ProductID
    JOIN employees e ON e.EmployeeID = v.SalesPersonID
)
SELECT
    ProductID,
    ProductName,
    Total_Vendido AS Cantidad_Total,
    SalesPersonID,
    CONCAT(FirstName, ' ', LastName) AS Nombre_Vendedor,
    Cantidad_Vendida AS Cantidad_Maxima_Vendida,
    ROUND(100 * Cantidad_Vendida / Total_Vendido, 2) AS Porcentaje_Participacion,
    CASE
        WHEN ROUND(100 * Cantidad_Vendida / Total_Vendido, 2) > 10 THEN '🔥 Vendedor clave'
        ELSE '—'
    END AS Etiqueta
FROM ranking_vendedores
WHERE Posicion = 1
ORDER BY Total_Vendido DESC;

-- 9.672 sec

CREATE INDEX idx_sales_product_seller_quantity 
ON sales (ProductID, SalesPersonID, Quantity);

CREATE INDEX idx_employees_id 
ON employees (EmployeeID);

CREATE INDEX idx_products_id 
ON products (ProductID);

-- 9.281 sec

-- OBSERVACIONES: En esta consulta, la optimización mediante índices permitió una reducción del tiempo total de ejecución
-- cercana al 4 %. Si bien el bloque analítico más pesado está en la jerarquía de ranking por producto,
-- los accesos indexados a sales, products y employees contribuyeron a agilizar el flujo general de datos.
-- Esto respalda la importancia de aplicar índices incluso en consultas aparentemente eficientes:
-- el impacto acumulado puede ser decisivo en entornos productivos con gran concurrencia.

-- ----------------------------------------------------------------

-- b. -- ¿Cuáles son los 10 productos con mayor cantidad de unidades vendidas en todo el catálogo y cuál es su posición dentro de su propia categoría?

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

-- 36.172 sec

-- Índice compuesto para acelerar el JOIN y la agregación
CREATE INDEX idx_sales_product_quantity 
ON sales (ProductID, Quantity);

-- Índice sobre ProductID en products para JOIN más eficiente
CREATE INDEX idx_products_productid 
ON products (ProductID, CategoryID);

-- Índice simple sobre CategoryID en categories
CREATE INDEX idx_categories_id 
ON categories (CategoryID);

-- 35.360 sec

-- OBSERVACIONES: Al aplicar índices en las columnas clave utilizadas en los JOIN y la agrupación (ProductID, Quantity, CategoryID),
-- se observó una mejora de ~2.2 % en el tiempo total de ejecución. Esto evidencia que el plan de ejecución logra
-- aprovechar el acceso optimizado a las tablas base, aunque el costo principal está en el procesamiento del ranking por categoría
-- y la ordenación global. Por lo tanto, la estrategia combinada de índices y reorganización de pasos lógicos es clave
-- para lograr mejoras más sustanciales.
