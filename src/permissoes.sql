-- --------------------------------------------------------------------------------------
-- Data de Criação ........: 30/08/2024                                                --
-- Autor(es) ..............: Fernando Gabriel, João A. e Julio Cesar                  --
-- Versão .................: 1.0                                                       --
-- Banco de Dados .........: PostgreSQL                                                --
-- Descrição ..............: Adiciona Triggers e restrições                            --
-- --------------------------------------------------------------------------------------

BEGIN;

---------------------
---
---   USUÁRIO PADRÃO
---
---------------------

CREATE ROLE prison_trading_user WITH
    LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    INHERIT
    NOREPLICATION
    NOBYPASSRLS
    CONNECTION LIMIT -1
    PASSWORD '123';
COMMENT ON ROLE prison_trading_user IS 'Usuário padrão para acesso ao banco de dados do jogo prison trading';

---------------------
---
---   PERMISSÕES
---
---------------------

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO prison_trading_user;

REVOKE INSERT, UPDATE, DELETE ON pessoa FROM prison_trading_user;

REVOKE INSERT, UPDATE, DELETE ON item, item_fabricavel, item_nao_fabricavel FROM prison_trading_user;

REVOKE INSERT, DELETE ON fabricacao, inventario FROM prison_trading_user;

---------------------
---
---   PESSOA
---
---------------------

CREATE FUNCTION insert_pessoa()
RETURNS trigger AS $insert_pessoa$
DECLARE
	id_pessoa INTEGER;
	tipo_pessoa TipoPessoa;
BEGIN
	id_pessoa = NEW.id;
	tipo_pessoa = NEW.tipo;

	RAISE NOTICE 'Id da pessoa é: % | Tipo da pessoa é: %', id_pessoa, tipo_pessoa;

	PERFORM 1 FROM prisioneiro WHERE id = id_pessoa;
	IF FOUND THEN
		RAISE EXCEPTION 'A pessoa com o id % e tipo % está na tabela prisioneiro, ação negada.', id_pessoa, tipo_pessoa;
	END IF;

	PERFORM 1 FROM policial WHERE id = id_pessoa;
	IF FOUND THEN
		RAISE EXCEPTION 'A pessoa com o id % e tipo % está na tabela policial, ação negada.', id_pessoa, tipo_pessoa;
	END IF;

	PERFORM 1 FROM informante WHERE id = id_pessoa;
	IF FOUND THEN
		RAISE EXCEPTION 'A pessoa com o id % e tipo % está na tabela informante, ação negada.', id_pessoa, tipo_pessoa;
	END IF;

	PERFORM 1 FROM jogador WHERE id = id_pessoa;
	IF FOUND THEN
		RAISE EXCEPTION 'A pessoa com o id % e tipo % está na tabela jogador, ação negada.', id_pessoa, tipo_pessoa;
	END IF;

	RAISE NOTICE 'O % não aparece em nenhuma outra tabela, a tupla é unica inserção em pessoa concedida.', tipo_pessoa;

	RETURN NEW;
END;
$insert_pessoa$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER insert_pessoa
BEFORE INSERT ON pessoa
FOR EACH ROW EXECUTE PROCEDURE insert_pessoa();

---------------------
---
---   JOGADOR
---
---------------------

CREATE FUNCTION insert_jogador()
RETURNS trigger AS $insert_jogador$
DECLARE
    jogador_id INTEGER;
BEGIN
	INSERT INTO pessoa (tipo)
	VALUES ('jogador')
	RETURNING id INTO jogador_id;

	INSERT INTO inventario (pessoa, inventario_ocupado, tamanho)
	VALUES (jogador_id, 0, 5);

	NEW.id := jogador_id;

	RAISE NOTICE 'Criação da pessoa e inventário foram um sucesso, id do jogador é: %', jogador_id;

    RETURN NEW;

END;
$insert_jogador$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER insert_jogador
BEFORE INSERT ON jogador
FOR EACH ROW EXECUTE PROCEDURE insert_jogador();

CREATE FUNCTION update_jogador()
RETURNS trigger AS $update_jogador$
BEGIN
	IF NEW.id <> OLD.id THEN
		-- Não deixa alterar id de jogador, se deixar tem q alterar pessoa, inventario e
		-- Instancias de item referenciando o inventario e pessoa.
		RAISE EXCEPTION 'Não é possível alterar o id do jogador.';
	END IF;

    RETURN NEW;

END;
$update_jogador$ LANGUAGE plpgsql;

CREATE TRIGGER update_jogador
BEFORE update ON jogador
FOR EACH ROW EXECUTE PROCEDURE update_jogador();

CREATE FUNCTION delete_jogador_before()
RETURNS trigger AS $delete_jogador_before$
DECLARE
    id_jogador INTEGER;
BEGIN
	id_jogador := OLD.id;

	DELETE FROM instancia_item WHERE pessoa = id_jogador;

	DELETE FROM inventario WHERE pessoa = id_jogador;

	RAISE NOTICE 'Todas as instancias de item referenciando o jogador foram deletadas, inclusive seu inventário.';

    RETURN OLD;

END;
$delete_jogador_before$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER delete_jogador_before
BEFORE DELETE ON jogador
FOR EACH ROW EXECUTE PROCEDURE delete_jogador_before();

CREATE FUNCTION delete_jogador_after()
RETURNS trigger AS $delete_jogador_after$
BEGIN
	DELETE FROM pessoa WHERE id = OLD.id;

	RAISE NOTICE 'A pessoa da tabela caracterizadora foi deletada.';

    RETURN OLD;

END;
$delete_jogador_after$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER delete_jogador_after
AFTER DELETE ON jogador
FOR EACH ROW EXECUTE PROCEDURE delete_jogador_after();

---------------------
---
---   PRISIONEIRO
---
---------------------

CREATE FUNCTION insert_prisioneiro()
RETURNS trigger AS $insert_prisioneiro$
DECLARE
    prisioneiro_id INTEGER;
BEGIN
	INSERT INTO pessoa (tipo)
	VALUES ('prisioneiro')
	RETURNING id INTO prisioneiro_id;

	INSERT INTO inventario (pessoa, inventario_ocupado, tamanho)
	VALUES (prisioneiro_id, 0, 5);

	NEW.id := prisioneiro_id;

	RAISE NOTICE 'Criação da pessoa e inventário foram um sucesso, id do prisioneiro é: %', prisioneiro_id;

    RETURN NEW;

END;
$insert_prisioneiro$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER prisioneiro_insert
BEFORE INSERT ON prisioneiro
FOR EACH ROW EXECUTE PROCEDURE insert_prisioneiro();

CREATE FUNCTION update_prisioneiro()
RETURNS trigger AS $update_prisioneiro$
BEGIN
	IF NEW.id <> OLD.id THEN
		-- Não deixa alterar id de prisioneiro, se deixar tem q alterar pessoa, inventario e
		-- Instancias de item referenciando o inventario e pessoa.
		RAISE EXCEPTION 'Não é possível alterar o id do prisioneiro.';
	END IF;

    RETURN NEW;

END;
$update_prisioneiro$ LANGUAGE plpgsql;

CREATE TRIGGER update_prisioneiro
BEFORE update ON prisioneiro
FOR EACH ROW EXECUTE PROCEDURE update_prisioneiro();

CREATE FUNCTION delete_prisioneiro_before()
RETURNS trigger AS $delete_prisioneiro_before$
DECLARE
    id_prisioneiro INTEGER;
BEGIN
	id_prisioneiro := OLD.id;

	DELETE FROM instancia_item WHERE pessoa = id_prisioneiro;

	DELETE FROM inventario WHERE pessoa = id_prisioneiro;

	RAISE NOTICE 'Todas as instancias de item referenciando o prisioneiro foram deletadas, inclusive seu inventário.';

    RETURN OLD;

END;
$delete_prisioneiro_before$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER delete_prisioneiro_before
BEFORE DELETE ON prisioneiro
FOR EACH ROW EXECUTE PROCEDURE delete_prisioneiro_before();

CREATE FUNCTION delete_prisioneiro_after()
RETURNS trigger AS $delete_prisioneiro_after$
BEGIN
	DELETE FROM pessoa WHERE id = OLD.id;

	RAISE NOTICE 'A pessoa da tabela caracterizadora foi deletada.';

    RETURN OLD;

END;
$delete_prisioneiro_after$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER delete_prisioneiro_after
AFTER DELETE ON prisioneiro
FOR EACH ROW EXECUTE PROCEDURE delete_prisioneiro_after();

---------------------
---
---   INFORMANTE
---
---------------------

CREATE FUNCTION insert_informante()
RETURNS trigger AS $insert_informante$
DECLARE
    informante_id INTEGER;
BEGIN
	INSERT INTO pessoa (tipo)
	VALUES ('informante')
	RETURNING id INTO informante_id;

	INSERT INTO inventario (pessoa, inventario_ocupado, tamanho)
	VALUES (informante_id, 0, 5);

	NEW.id := informante_id;

    RAISE NOTICE 'Criação da pessoa e inventário foram um sucesso, id do informante é: %', informante_id;

    RETURN NEW;

END;
$insert_informante$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER informante_insert
BEFORE INSERT ON informante
FOR EACH ROW EXECUTE PROCEDURE insert_informante();

CREATE FUNCTION update_informante()
RETURNS trigger AS $update_informante$
BEGIN
	IF NEW.id <> OLD.id THEN
		-- Não deixa alterar id de informante, se deixar tem q alterar pessoa, inventario e
		-- Instancias de item referenciando o inventario e pessoa.
		RAISE EXCEPTION 'Não é possível alterar o id do informante.';
	END IF;

    RETURN NEW;

END;
$update_informante$ LANGUAGE plpgsql;

CREATE TRIGGER update_informante
BEFORE update ON informante
FOR EACH ROW EXECUTE PROCEDURE update_informante();

CREATE FUNCTION delete_informante_before()
RETURNS trigger AS $delete_informante_before$
DECLARE
    id_informante INTEGER;
BEGIN
	id_informante := OLD.id;

	DELETE FROM instancia_item WHERE pessoa = id_informante;

	DELETE FROM inventario WHERE pessoa = id_informante;

	RAISE NOTICE 'Todas as instancias de item referenciando o informante foram deletadas, inclusive seu inventário.';

    RETURN OLD;

END;
$delete_informante_before$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER delete_informante_before
BEFORE DELETE ON informante
FOR EACH ROW EXECUTE PROCEDURE delete_informante_before();

CREATE FUNCTION delete_informante_after()
RETURNS trigger AS $delete_informante_after$
BEGIN
	DELETE FROM pessoa WHERE id = OLD.id;

	RAISE NOTICE 'A pessoa da tabela caracterizadora foi deletada.';

    RETURN OLD;

END;
$delete_informante_after$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER delete_informante_after
AFTER DELETE ON informante
FOR EACH ROW EXECUTE PROCEDURE delete_informante_after();

---------------------
---
---   POLICIAL
---
---------------------

CREATE FUNCTION insert_policial()
RETURNS trigger AS $insert_policial$
DECLARE
    policial_id INTEGER;
BEGIN
	INSERT INTO pessoa (tipo)
	VALUES ('policial')
	RETURNING id INTO policial_id;

	INSERT INTO inventario (pessoa, inventario_ocupado, tamanho)
	VALUES (policial_id, 0, 5);

	NEW.id := policial_id;

	RAISE NOTICE 'Criação da pessoa e inventário foram um sucesso, id do policial é: %', policial_id;

    RETURN NEW;

END;
$insert_policial$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER policial_insert
BEFORE INSERT ON policial
FOR EACH ROW EXECUTE PROCEDURE insert_policial();

CREATE FUNCTION update_policial()
RETURNS trigger AS $update_policial$
BEGIN
	IF NEW.id <> OLD.id THEN
		-- Não deixa alterar id de policial, se deixar tem q alterar pessoa, inventario e
		-- Instancias de item referenciando o inventario e pessoa.
		RAISE EXCEPTION 'Não é possível alterar o id do policial.';
	END IF;

    RETURN NEW;

END;
$update_policial$ LANGUAGE plpgsql;

CREATE TRIGGER update_policial
BEFORE update ON policial
FOR EACH ROW EXECUTE PROCEDURE update_policial();

CREATE FUNCTION delete_policial_before()
RETURNS trigger AS $delete_policial_before$
DECLARE
    id_policial INTEGER;
BEGIN
	id_policial := OLD.id;

	DELETE FROM instancia_item WHERE pessoa = id_policial;

	DELETE FROM inventario WHERE pessoa = id_policial;

	RAISE NOTICE 'Todas as instancias de item referenciando o policial foram deletadas, inclusive seu inventário.';

    RETURN OLD;

END;
$delete_policial_before$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER delete_policial_before
BEFORE DELETE ON policial
FOR EACH ROW EXECUTE PROCEDURE delete_policial_before();

CREATE FUNCTION delete_policial_after()
RETURNS trigger AS $delete_policial_after$
BEGIN
	DELETE FROM pessoa WHERE id = OLD.id;

	RAISE NOTICE 'A pessoa da tabela caracterizadora foi deletada.';

    RETURN OLD;

END;
$delete_policial_after$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER delete_policial_after
AFTER DELETE ON policial
FOR EACH ROW EXECUTE PROCEDURE delete_policial_after();

---------------------
---
---   INVENTARIO
---
---------------------

CREATE FUNCTION update_inventario()
RETURNS trigger AS $update_inventario$
BEGIN
	IF NEW.tamanho <> OLD.tamanho OR NEW.inventario_ocupado <> OLD.inventario_ocupado THEN
	   	RAISE NOTICE 'Operação foi um sucesso.';
		RETURN NEW;
	ELSE
	    RAISE EXCEPTION 'Só é possivel alterar o tamanho total do inventário.';
	END IF;

END;
$update_inventario$ LANGUAGE plpgsql;

CREATE TRIGGER update_inventario
BEFORE update ON inventario
FOR EACH ROW EXECUTE PROCEDURE update_inventario();

---------------------
---
---   INSTANCIA_ITEM
---
---------------------

CREATE FUNCTION insert_instancia()
RETURNS trigger AS $insert_instancia$
BEGIN
    IF NEW.lugar IS NULL AND NEW.inventario IS NULL THEN
        RAISE EXCEPTION 'Atualizando inventário e lugar como valores nulos.';
    ELSIF NEW.lugar IS NOT NULL AND NEW.inventario IS NOT NULL THEN
        RAISE EXCEPTION 'A instância não pode estar em um lugar e inventário ao mesmo tempo.';
    END IF;

    RETURN NEW;
END;
$insert_instancia$ LANGUAGE plpgsql;

CREATE TRIGGER insert_instancia
BEFORE INSERT ON instancia_item
FOR EACH ROW EXECUTE PROCEDURE insert_instancia();

CREATE FUNCTION update_instancia()
RETURNS trigger AS $update_instancia$
DECLARE
    inventario_atb INTEGER;
    item_atb INTEGER;
    inventario_ocupado_atb SMALLINT;
    tamanho_inventario_atb INTEGER;
    tamanho_item_atb INTEGER;
    total_atb SMALLINT;
    lugar_jogador_atb INTEGER;

BEGIN
    IF NEW.lugar IS NULL AND NEW.inventario IS NULL THEN
        RAISE EXCEPTION 'Atualizando inventário e lugar como valores nulos.';
    ELSIF NEW.lugar IS NOT NULL AND NEW.inventario IS NOT NULL THEN
        RAISE EXCEPTION 'A instância não pode estar em um lugar e inventário ao mesmo tempo.';
    END IF;

    inventario_atb := NEW.inventario;
    item_atb := NEW.item;

    SELECT inventario_ocupado, tamanho INTO inventario_ocupado_atb, tamanho_inventario_atb
    FROM inventario
    WHERE id = inventario_atb;

    SELECT COALESCE(arm.tamanho, fer.tamanho, com.tamanho, med.tamanho, uti.tamanho) INTO tamanho_item_atb
    FROM item ite
    LEFT JOIN arma arm ON arm.id = ite.id
    LEFT JOIN ferramenta fer ON fer.id = ite.id
    LEFT JOIN comida com ON com.id = ite.id
    LEFT JOIN medicamento med ON med.id = ite.id
    LEFT JOIN utilizavel uti ON uti.id = ite.id
    WHERE ite.id = item_atb;

    IF OLD.lugar IS DISTINCT FROM NEW.lugar THEN

        IF NEW.pessoa IS NOT NULL THEN
            SELECT lugar INTO lugar_jogador_atb
            FROM jogador
            WHERE id = NEW.pessoa;
            IF lugar_jogador_atb <> OLD.lugar THEN
                RAISE EXCEPTION 'Jogador não pode pegar o item, pois não está no mesmo lugar da instância.';
            END IF;
        ELSE
            SELECT lugar INTO lugar_jogador_atb
            FROM jogador
            WHERE id = OLD.pessoa;
            IF lugar_jogador_atb <> NEW.lugar THEN
                RAISE EXCEPTION 'Jogador não pode dropar o item, pois não está no mesmo lugar de onde vai dropar.';
            END IF;
        END IF;

    END IF;

    IF NEW.inventario IS NULL THEN
        SELECT inventario_ocupado INTO inventario_ocupado_atb
        FROM inventario
        WHERE id = OLD.inventario;

        total_atb := inventario_ocupado_atb - tamanho_item_atb;

        RAISE NOTICE 'Joguou Item fora - inventário ocupado: %', total_atb;

        UPDATE inventario
        SET inventario_ocupado = total_atb
        WHERE id = OLD.inventario;

    ELSIF NEW.inventario IS NOT NULL THEN

        total_atb := inventario_ocupado_atb + tamanho_item_atb;

        IF total_atb > tamanho_inventario_atb THEN
         	RAISE EXCEPTION 'Espaço insuficiente no inventário. Atualização bloqueada. Total ocupado: % | Tamanho do item: % | Total atual: %',
          	inventario_ocupado_atb, tamanho_item_atb, total_atb;
        END IF;

        RAISE NOTICE 'Pegou Item - inventário ocupado: %', total_atb;

        UPDATE inventario
        SET inventario_ocupado = total_atb
        WHERE id = inventario_atb;

    END IF;

    RETURN NEW;

END;
$update_instancia$ LANGUAGE plpgsql;

CREATE TRIGGER update_instancia
BEFORE UPDATE ON instancia_item
FOR EACH ROW EXECUTE PROCEDURE update_instancia();

CREATE FUNCTION delete_instancia()
RETURNS trigger AS $delete_instancia$
DECLARE
    item_atb INTEGER;
    inventario_ocupado_atb SMALLINT;
    tamanho_item_atb INTEGER;
    total_atb SMALLINT;
BEGIN

    IF OLD.inventario IS NOT NULL THEN
        item_atb := OLD.item;

        SELECT COALESCE(arm.tamanho, fer.tamanho, com.tamanho, med.tamanho, uti.tamanho) INTO tamanho_item_atb
        FROM item ite
        LEFT JOIN arma arm ON arm.id = ite.id
        LEFT JOIN ferramenta fer ON fer.id = ite.id
        LEFT JOIN comida com ON com.id = ite.id
        LEFT JOIN medicamento med ON med.id = ite.id
        LEFT JOIN utilizavel uti ON uti.id = ite.id
        WHERE ite.id = item_atb;

        SELECT inventario_ocupado INTO inventario_ocupado_atb
        FROM inventario
        WHERE id = OLD.inventario;

        total_atb := inventario_ocupado_atb - tamanho_item_atb;

        RAISE NOTICE 'Joguou Item fora - inventário ocupado: %', total_atb;

        UPDATE inventario
        SET inventario_ocupado = total_atb
        WHERE id = OLD.inventario;

    END IF;

    RETURN OLD;
END;
$delete_instancia$ LANGUAGE plpgsql;

CREATE TRIGGER delete_instancia
BEFORE DELETE ON instancia_item
FOR EACH ROW EXECUTE PROCEDURE delete_instancia();

COMMIT;
