from fastapi import APIRouter, HTTPException
from db import get_connection

router = APIRouter()

@router.get("/painel/{id_usuario}")
def painel(id_usuario: int):
    con = get_connection()
    cur = con.cursor(dictionary=True)

    try:
        # Usuário
        cur.execute(
            "SELECT nome FROM usuarios WHERE id_usuario = %s",
            (id_usuario,)
        )
        usuario = cur.fetchone()
        if not usuario:
            raise HTTPException(404, "Usuário não encontrado")

        # Eventos
        cur.execute(
            "SELECT COUNT(*) AS total FROM eventos WHERE id_usuario = %s",
            (id_usuario,)
        )
        total_eventos = cur.fetchone()["total"]

        cur.execute(
            """SELECT COUNT(*) AS total 
               FROM eventos 
               WHERE id_usuario = %s 
               AND status IN ('ativo','agendado')""",
            (id_usuario,)
        )
        eventos_ativos = cur.fetchone()["total"]

        # Categorias
        cur.execute(
            "SELECT COUNT(*) AS total FROM catalogo_categorias WHERE id_usuario = %s",
            (id_usuario,)
        )
        total_categorias = cur.fetchone()["total"]

        # Itens
        cur.execute(
            "SELECT COUNT(*) AS total FROM catalogo_itens WHERE id_usuario = %s",
            (id_usuario,)
        )
        total_itens = cur.fetchone()["total"]

        return {
            "nome_usuario": usuario["nome"],
            "total_eventos": total_eventos,
            "eventos_ativos": eventos_ativos,
            "total_categorias": total_categorias,
            "total_itens": total_itens
        }

    finally:
        cur.close()
        con.close()
