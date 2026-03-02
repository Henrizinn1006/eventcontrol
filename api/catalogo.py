from fastapi import APIRouter, HTTPException, UploadFile, File, Form, Request, Query
from fastapi.responses import Response
from pydantic import BaseModel
from db import get_connection

router = APIRouter()

# MODELS (para Swagger / Postman)

class CategoriaIn(BaseModel):
    id_usuario: int
    nome_categoria: str

class ItemEditIn(BaseModel):
    id_usuario: int
    nome_item: str
    abreviacao: str = ""
    quantidade_total: int

# HELPERS

async def _get_json_body(request: Request) -> dict:
    try:
        return await request.json()
    except Exception:
        return {}

def _strip(v) -> str:
    return (v or "").strip()

# CATEGORIAS

@router.get("/categorias/{id_usuario}")
def listar_categorias(id_usuario: int):
    con = get_connection()
    cur = con.cursor(dictionary=True)
    try:
        cur.execute("""
            SELECT id_categoria, nome_categoria
            FROM catalogo_categorias
            WHERE id_usuario=%s
            ORDER BY nome_categoria
        """, (id_usuario,))
        return {"sucesso": True, "dados": cur.fetchall()}
    finally:
        cur.close()
        con.close()


@router.post("/categorias")
async def criar_categoria(
    request: Request,
    id_usuario: int | None = Form(None),
    nome_categoria: str | None = Form(None),
):
    if id_usuario is None or nome_categoria is None:
        body = await _get_json_body(request)
        id_usuario = id_usuario if id_usuario is not None else body.get("id_usuario")
        nome_categoria = nome_categoria if nome_categoria is not None else body.get("nome_categoria")

    if id_usuario is None:
        raise HTTPException(422, "id_usuario obrigatório")
    nome = _strip(nome_categoria)
    if not nome:
        raise HTTPException(400, "Nome da categoria inválido")

    con = get_connection()
    cur = con.cursor()
    try:
        cur.execute("""
            INSERT INTO catalogo_categorias (id_usuario, nome_categoria)
            VALUES (%s, %s)
        """, (id_usuario, nome))
        con.commit()
        return {"sucesso": True}
    finally:
        cur.close()
        con.close()

@router.put("/categorias/{id_categoria}")
async def editar_categoria(
    id_categoria: int,
    request: Request,
    id_usuario: int | None = Form(None),
    nome: str | None = Form(None),
):
    if id_usuario is None or nome is None:
        body = await _get_json_body(request)
        id_usuario = id_usuario if id_usuario is not None else body.get("id_usuario")
        nome = nome if nome is not None else body.get("nome")

    if id_usuario is None:
        raise HTTPException(422, "id_usuario obrigatório")

    nome = _strip(nome)
    if not nome:
        raise HTTPException(400, "Nome da categoria inválido")

    con = get_connection()
    cur = con.cursor()
    try:
        cur.execute("""
            UPDATE catalogo_categorias
            SET nome_categoria=%s
            WHERE id_categoria=%s AND id_usuario=%s
        """, (nome, id_categoria, id_usuario))

        if cur.rowcount == 0:
            raise HTTPException(404, "Categoria não encontrada")

        con.commit()
        return {"sucesso": True}
    finally:
        cur.close()
        con.close()


@router.delete("/categorias/{id_categoria}")
def excluir_categoria(id_usuario: int, id_categoria: int):
    con = get_connection()
    cur = con.cursor()
    try:
        cur.execute("""
            SELECT COUNT(*)
            FROM catalogo_itens
            WHERE id_categoria=%s AND id_usuario=%s
        """, (id_categoria, id_usuario))

        if cur.fetchone()[0] > 0:
            raise HTTPException(400, "Categoria possui itens")

        cur.execute("""
            DELETE FROM catalogo_categorias
            WHERE id_categoria=%s AND id_usuario=%s
        """, (id_categoria, id_usuario))

        if cur.rowcount == 0:
            raise HTTPException(404, "Categoria não encontrada")

        con.commit()
        return {"sucesso": True}
    finally:
        cur.close()
        con.close()

# ITENS

def _quantidade_disponivel(cur, id_usuario: int, id_item: int) -> int:
    # total do catálogo
    cur.execute("""
        SELECT quantidade_total
        FROM catalogo_itens
        WHERE id_item=%s AND id_usuario=%s
    """, (id_item, id_usuario))

    row = cur.fetchone()
    if not row:
        raise HTTPException(404, "Item não encontrado")

    total = row[0] if not isinstance(row, dict) else row["quantidade_total"]

    # já reservados em eventos ativos
    cur.execute("""
        SELECT COALESCE(
            SUM(ie.quantidade_locada - ie.quantidade_devolvida),
            0
        )
        FROM itens_evento ie
        JOIN eventos e ON e.id_evento = ie.id_evento
        WHERE ie.id_item=%s
          AND e.id_usuario=%s
          AND e.status IN ('agendado','ativo')
    """, (id_item, id_usuario))

    reservados = cur.fetchone()[0]
    return max(0, total - reservados)


@router.get("/categorias/{id_categoria}/itens")
def listar_itens(
    id_categoria: int,
    id_usuario: int = Query(...)
):
    con = get_connection()
    cur = con.cursor(dictionary=True)
    try:
        cur.execute("""
            SELECT id_item, nome_item, abreviacao, quantidade_total
            FROM catalogo_itens
            WHERE id_categoria=%s AND id_usuario=%s
            ORDER BY nome_item
        """, (id_categoria, id_usuario))

        itens = cur.fetchall()
        for it in itens:
            it["quantidade_disponivel"] = _quantidade_disponivel(
                cur, id_usuario, it["id_item"]
            )

        return {"sucesso": True, "dados": itens}
    finally:
        cur.close()
        con.close()


@router.post("/itens")
def criar_item(
    id_usuario: int = Form(...),
    id_categoria: int = Form(...),
    nome: str = Form(...),
    abreviacao: str = Form(""),
    quantidade_total: int = Form(...),
    imagem: UploadFile = File(...)
):
    nome = _strip(nome)
    abreviacao = _strip(abreviacao)

    if not nome:
        raise HTTPException(400, "Nome inválido")
    if quantidade_total < 0:
        raise HTTPException(400, "Quantidade inválida")

    imagem_bytes = imagem.file.read()

    con = get_connection()
    cur = con.cursor()
    try:
        cur.execute("""
            INSERT INTO catalogo_itens
            (id_usuario, id_categoria, nome_item, abreviacao, quantidade_total, imagem)
            VALUES (%s,%s,%s,%s,%s,%s)
        """, (id_usuario, id_categoria, nome, abreviacao, quantidade_total, imagem_bytes))

        con.commit()
        return {"sucesso": True}
    finally:
        cur.close()
        con.close()


@router.put("/itens/{id_item}")
def editar_item(
    id_item: int,
    id_usuario: int,
    nome: str,
    quantidade_total: int
):
    con = get_connection()
    cur = con.cursor()

    cur.execute("""
        UPDATE catalogo_itens
        SET nome_item=%s, quantidade_total=%s
        WHERE id_item=%s AND id_usuario=%s
    """, (nome, quantidade_total, id_item, id_usuario))

    if cur.rowcount == 0:
        raise HTTPException(404, "Item não encontrado")

    con.commit()
    cur.close()
    con.close()

    return {"sucesso": True}


@router.get("/imagens/itens/{id_item}")
def imagem_item(
    id_item: int,
    id_usuario: int = Query(...)
):
    con = get_connection()
    cur = con.cursor(dictionary=True)

    cur.execute("""
        SELECT imagem
        FROM catalogo_itens
        WHERE id_item=%s AND id_usuario=%s
    """, (id_item, id_usuario))

    row = cur.fetchone()
    cur.close()
    con.close()

    if not row or not row["imagem"]:
        raise HTTPException(404, "Imagem não encontrada")

    return Response(row["imagem"], media_type="image/*")


@router.delete("/itens/{id_item}")
def excluir_item(
    id_item: int,
    id_usuario: int
):
    con = get_connection()
    cur = con.cursor()

    cur.execute("""
        DELETE FROM catalogo_itens
        WHERE id_item=%s AND id_usuario=%s
    """, (id_item, id_usuario))

    if cur.rowcount == 0:
        raise HTTPException(404, "Item não encontrado")

    con.commit()
    cur.close()
    con.close()

    return {"sucesso": True}
