CREATE DATABASE Prod;
USE Prod;

CREATE TABLE Clientes (
    ClienteID INT PRIMARY KEY IDENTITY(1,1),
    Nome NVARCHAR(100) NOT NULL,
    Cidade NVARCHAR(50),
    DataCadastro DATE DEFAULT GETDATE()
);

CREATE TABLE Pedidos (
    PedidoID INT PRIMARY KEY IDENTITY(1,1),
    ClienteID INT NOT NULL,
    DataPedido DATE DEFAULT GETDATE(),
    ValorTotal DECIMAL(18, 2) NOT NULL,
    DescAplicado DECIMAL(5, 2) DEFAULT 0,
    FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID)
);

CREATE TABLE Produtos (
    ProdutoID INT PRIMARY KEY IDENTITY(1,1),
    NomeProduto NVARCHAR(100) NOT NULL,
    Categoria NVARCHAR(50),
    Preco DECIMAL(18, 2) NOT NULL
);

CREATE TABLE ItensPedidos (
    ItemID INT PRIMARY KEY IDENTITY(1,1),
    PedidoID INT NOT NULL,
    ProdutoID INT NOT NULL,
    Quantidade INT NOT NULL,
    PrecoUnitario DECIMAL(18, 2) NOT NULL,
    FOREIGN KEY (PedidoID) REFERENCES Pedidos(PedidoID),
    FOREIGN KEY (ProdutoID) REFERENCES Produtos(ProdutoID)
);

INSERT INTO Clientes (Nome, Cidade) VALUES 
('Jo�o Silva', 'S�o Paulo'),
('Maria Oliveira', 'Rio de Janeiro'),
('Pedro Santos', 'Belo Horizonte');

INSERT INTO Produtos (NomeProduto, Categoria, Preco) VALUES
('Notebook', 'Eletr�nicos', 3500.00),
('Smartphone', 'Eletr�nicos', 1500.00),
('Geladeira', 'Eletrodom�sticos', 2000.00),
('Fog�o', 'Eletrodom�sticos', 800.00);

INSERT INTO Pedidos (ClienteID, ValorTotal) VALUES
(1, 7000.00),
(2, 3000.00),
(3, 15000.00);

INSERT INTO ItensPedidos (PedidoID, ProdutoID, Quantidade, PrecoUnitario) VALUES
(1, 1, 1, 3500.00),
(1, 3, 1, 2000.00),
(2, 2, 2, 1500.00),
(3, 4, 10, 800.00); 

GO
--1
CREATE PROCEDURE ConsultaClientes
AS
BEGIN
    SELECT
        c.ClienteID,
        c.Nome AS Cliente,
        c.Cidade,
        MONTH(p.DataPedido) AS Mes,
        SUM(i.Quantidade * i.PrecoUnitario) AS TotalGasto,
        (SELECT TOP 1 pr.NomeProduto
         FROM ItensPedidos i2
         JOIN Produtos pr ON i2.Produtos_ProdutoID = pr.ProdutoID
         WHERE i2.Pedidos_PedidoID = p.PedidoID
         ORDER BY i2.Quantidade * i2.PrecoUnitario DESC) AS ProdutoMaisCaro
    FROM
        Clientes c
    JOIN
        Pedidos p ON c.ClienteID = p.Clientes_ClienteID
    JOIN
        ItensPedidos i ON p.PedidoID = i.Pedidos_PedidoID
    WHERE
        p.DataPedido >= DATEADD(MONTH, -3, GETDATE())
    GROUP BY
        c.ClienteID, c.Nome, c.Cidade, MONTH(p.DataPedido), p.PedidoID
    HAVING
        SUM(i.Quantidade * i.PrecoUnitario) > 5000.00
END;

GO
--2
CREATE PROCEDURE CalculoDescontos
AS
BEGIN
    UPDATE p
    SET DescAplicado = CASE 
        WHEN (SELECT SUM(Quantidade) FROM ItensPedidos WHERE PedidoID = p.PedidoID) > 30 
            AND ValorTotal >= 10 * (SELECT SUM(Quantidade) FROM ItensPedidos WHERE PedidoID = p.PedidoID)
            THEN 15
        WHEN (SELECT SUM(Quantidade) FROM ItensPedidos WHERE PedidoID = p.PedidoID) > 20 
            AND ValorTotal >= 10 * (SELECT SUM(Quantidade) FROM ItensPedidos WHERE PedidoID = p.PedidoID)
            THEN 10
        WHEN (SELECT SUM(Quantidade) FROM ItensPedidos WHERE PedidoID = p.PedidoID) > 10 
            AND ValorTotal >= 10 * (SELECT SUM(Quantidade) FROM ItensPedidos WHERE PedidoID = p.PedidoID)
            THEN 5
        ELSE 1
    END
    FROM Pedidos p
    JOIN Clientes c ON p.ClienteID = c.ClienteID
    WHERE c.ClienteID IN (SELECT ClienteID FROM @clientesAcimaDe5000)
      AND MONTH(p.DataPedido) = MONTH(GETDATE());
END;

GO
--3
CREATE PROCEDURE IteracaoProdutosSimplificada
AS
BEGIN
    -- Produtos Vendidos por Categoria
    PRINT 'Produtos vendidos por categoria:';
    SELECT
        pr.Categoria,
        pr.NomeProduto
    FROM
        Produtos pr
    JOIN
        ItensPedidos i ON pr.ProdutoID = i.ProdutoID
    GROUP BY
        pr.Categoria, pr.NomeProduto
    ORDER BY
        pr.Categoria, pr.NomeProduto;

    -- Produtos Não Vendidos
    PRINT 'Produtos não vendidos:';
    SELECT
        pr.Categoria,
        pr.NomeProduto
    FROM
        Produtos pr
    LEFT JOIN
        ItensPedidos i ON pr.ProdutoID = i.ProdutoID
    WHERE
        i.ProdutoID IS NULL
    ORDER BY
        pr.Categoria, pr.NomeProduto;
END;

GO
--4
CREATE PROCEDURE RelatorioFinal
AS
BEGIN
    SELECT
        c.Nome AS NomeCliente,
        p.DataPedido,
        p.ValorTotal AS ValorOriginalPedido,
        p.ValorTotal * (1 - p.DescAplicado / 100.0) AS ValorFinalPedido,
        (SELECT SUM(Quantidade) FROM ItensPedidos WHERE PedidoID = p.PedidoID) AS QuantidadeProdutosComprados
    FROM
        Pedidos p
    JOIN
        Clientes c ON p.ClienteID = c.ClienteID
    WHERE
        MONTH(p.DataPedido) = MONTH(GETDATE());
END;

EXEC exercicio1;