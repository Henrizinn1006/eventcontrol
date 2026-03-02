from fastapi import APIRouter, HTTPException, UploadFile, File, Form, Query
from fastapi.responses import Response
from db import get_connection

router = APIRouter()

# LISTAR ITENS (por categoria + usuário)

@router.get("/")
def listar_itens(
    id_categoria: int = Query(...),
    id_usuario: int = Query(...)
):
    con = get_connection()
    cur = con.cursor(dictionary=True)
    try:
        # Busca itens do catálogo
        cur.execute("""
            SELECT id_item, nome_item, abreviacao, quantidade_total
            FROM catalogo_itens
            WHERE id_categoria=%s AND id_usuario=%s
            ORDER BY nome_item
        """, (id_categoria, id_usuario))

        itens = cur.fetchall()

        # Calcula quantidade_disponivel para cada item
        for it in itens:
            cur.execute("""
                SELECT COALESCE(SUM(ie.quantidade_locada - ie.quantidade_devolvida), 0)
                FROM itens_evento ie
                JOIN eventos e ON e.id_evento = ie.id_evento
                WHERE ie.id_item=%s
                  AND e.id_usuario=%s
                  AND e.status IN ('agendado','ativo')
            """, (it["id_item"], id_usuario))

            reservados = cur.fetchone()["COALESCE(SUM(ie.quantidade_locada - ie.quantidade_devolvida), 0)"]
            it["quantidade_disponivel"] = max(0, it["quantidade_total"] - reservados)

        return {"sucesso": True, "dados": itens}

    finally:
        cur.close()
        con.close()

# CRIAR ITEM


@router.post("/")
def criar_item(
    id_usuario: int = Form(...),
    id_categoria: int = Form(...),
    nome: str = Form(...),
    abreviacao: str = Form(""),
    quantidade_total: int = Form(...),
    imagem: UploadFile = File(...)
):
    nome = (nome or "").strip()
    abreviacao = (abreviacao or "").strip()

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

# EDITAR ITEM

@router.put("/{id_item}")
def editar_item(
    id_item: int,
    id_usuario: int = Form(...),
    nome: str = Form(...),
    abreviacao: str = Form(""),
    quantidade_total: int = Form(...)
):
    nome = (nome or "").strip()
    abreviacao = (abreviacao or "").strip()

    if not nome:
        raise HTTPException(400, "Nome inválido")

    con = get_connection()
    cur = con.cursor()
    try:
        cur.execute("""
            UPDATE catalogo_itens
            SET nome_item=%s,
                abreviacao=%s,
                quantidade_total=%s
            WHERE id_item=%s AND id_usuario=%s
        """, (nome, abreviacao, quantidade_total, id_item, id_usuario))

        if cur.rowcount == 0:
            raise HTTPException(404, "Item não encontrado")

        con.commit()
        return {"sucesso": True}
    finally:
        cur.close()
        con.close()

# ATUALIZAR IMAGEM DO ITEM


@router.put("/{id_item}/imagem")
def atualizar_imagem(
    id_item: int,
    id_usuario: int = Form(...),
    imagem: UploadFile = File(...)
):
    imagem_bytes = imagem.file.read()

    con = get_connection()
    cur = con.cursor()
    try:
        cur.execute("""
            UPDATE catalogo_itens
            SET imagem=%s
            WHERE id_item=%s AND id_usuario=%s
        """, (imagem_bytes, id_item, id_usuario))

        if cur.rowcount == 0:
            raise HTTPException(404, "Item não encontrado")

        con.commit()
        return {"sucesso": True}
    finally:
        cur.close()
        con.close()


# BUSCAR IMAGEM DO ITEM

@router.get("/{id_item}/imagem")
def imagem_item(
    id_item: int,
    id_usuario: int = Query(...)
):
    con = get_connection()
    cur = con.cursor()
    try:
        cur.execute("""
            SELECT imagem
            FROM catalogo_itens
            WHERE id_item=%s AND id_usuario=%s
        """, (id_item, id_usuario))

        row = cur.fetchone()
        if not row or not row[0]:
            raise HTTPException(404, "Imagem não encontrada")

        return Response(content=row[0], media_type="image/*")
    finally:
        cur.close()
        con.close()


# EXCLUIR ITEM

@router.delete("/{id_item}")
def excluir_item(
    id_item: int,
    id_usuario: int = Query(...)
):
    con = get_connection()
    cur = con.cursor()
    try:
        cur.execute("""
            DELETE FROM catalogo_itens
            WHERE id_item=%s AND id_usuario=%s
        """, (id_item, id_usuario))

        if cur.rowcount == 0:
            raise HTTPException(404, "Item não encontrado")

        con.commit()
        return {"sucesso": True}
    finally:
        cur.close()
        con.close()
