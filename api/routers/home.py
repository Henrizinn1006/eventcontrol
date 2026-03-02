from fastapi import APIRouter, HTTPException, Form
from db import get_connection

router = APIRouter()

@router.get("/painel/{id_usuario}")
def dados_painel(id_usuario: int):
    try:
        con = get_connection()
        cur = con.cursor(dictionary=True)

        # Usuário
        cur.execute(
            "SELECT nome FROM usuarios WHERE id_usuario = %s",
            (id_usuario,)
        )
        usuario = cur.fetchone()
        if not usuario:
            raise HTTPException(404, "Usuário não encontrado")

        # Eventos do usuário
        cur.execute(
            "SELECT COUNT(*) AS total FROM eventos WHERE id_usuario = %s",
            (id_usuario,)
        )
        eventos = cur.fetchone()["total"]

        # Itens do catálogo
        cur.execute(
            "SELECT COUNT(*) AS total FROM catalogo_itens WHERE id_usuario = %s",
            (id_usuario,)
        )
        itens = cur.fetchone()["total"]

        cur.close()
        con.close()

        return {
            "nome_usuario": usuario["nome"],
            "total_eventos": eventos,
            "total_itens": itens
        }

    except Exception as e:
        print("ERRO HOME:", e)
        raise HTTPException(500, "Erro interno na Home")


@router.put("/empresa")
def atualizar_nome_empresa(
    id_usuario: int = Form(...),
    nome_empresa: str = Form(...)
):
    nome_empresa = (nome_empresa or "").strip()

    if not nome_empresa:
        raise HTTPException(400, "Nome inválido")

    con = get_connection()
    cur = con.cursor()
    try:
        cur.execute("""
            UPDATE usuarios
            SET nome_empresa=%s
            WHERE id_usuario=%s
        """, (nome_empresa, id_usuario))

        if cur.rowcount == 0:
            raise HTTPException(404, "Usuário não encontrado")

        con.commit()
        return {"sucesso": True}
    finally:
        cur.close()
        con.close()
