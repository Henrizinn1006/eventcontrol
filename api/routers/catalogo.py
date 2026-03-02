from fastapi import APIRouter, HTTPException, UploadFile, File, Form, Request, Query
from fastapi.responses import Response, FileResponse
from db import get_connection
import os
import mimetypes
import tempfile
from datetime import datetime
import io
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader
from reportlab.lib import colors

router = APIRouter()

# HELPERS

async def _get_json_body(request: Request) -> dict:
    try:
        return await request.json()
    except Exception:
        return {}

def _strip(v) -> str:
    return (v or "").strip()

def _quantidade_reservada_em_eventos(cur, id_usuario: int, id_item: int) -> int:
    """
    Soma o que está 'em uso' (locada - devolvida) em eventos agendados/ativos.
    Isso garante que você não reduza o estoque abaixo do que já está comprometido.
    """
    cur.execute("""
        SELECT COALESCE(SUM(ie.quantidade_locada - ie.quantidade_devolvida), 0)
        FROM itens_evento ie
        JOIN eventos e ON e.id_evento = ie.id_evento
        WHERE ie.id_item=%s
          AND e.id_usuario=%s
          AND e.status IN ('agendado','ativo')
    """, (id_item, id_usuario))
    return int(cur.fetchone()[0] or 0)

def _item_existe(cur, id_usuario: int, id_item: int) -> bool:
    cur.execute("""
        SELECT 1
        FROM catalogo_itens
        WHERE id_item=%s AND id_usuario=%s
    """, (id_item, id_usuario))
    return cur.fetchone() is not None

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
        id_usuario = id_usuario or body.get("id_usuario")
        nome_categoria = nome_categoria or body.get("nome_categoria")

    if not id_usuario:
        raise HTTPException(422, "id_usuario obrigatório")

    nome = _strip(nome_categoria)
    if not nome:
        raise HTTPException(400, "Nome inválido")

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
        id_usuario = id_usuario or body.get("id_usuario")
        nome = nome or body.get("nome")

    if not id_usuario:
        raise HTTPException(422, "id_usuario obrigatório")

    nome = _strip(nome)
    if not nome:
        raise HTTPException(400, "Nome inválido")

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
def excluir_categoria(id_categoria: int, id_usuario: int = Query(...)):
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

@router.get("/itens/{id_categoria}/{id_usuario}")
def listar_itens(id_categoria: int, id_usuario: int):
    con = get_connection()
    cur = con.cursor(dictionary=True)

    try:
        cur.execute("""
            SELECT
                ci.id_item,
                ci.nome_item,
                ci.abreviacao,
                ci.quantidade_total,

                GREATEST(
                    ci.quantidade_total -
                    COALESCE(SUM(
                        CASE
                            WHEN e.status IN ('agendado','ativo')
                            THEN ie.quantidade_locada - ie.quantidade_devolvida
                            ELSE 0
                        END
                    ), 0),
                    0
                ) AS quantidade_disponivel

            FROM catalogo_itens ci
            LEFT JOIN itens_evento ie
                ON ie.id_item = ci.id_item
            LEFT JOIN eventos e
                ON e.id_evento = ie.id_evento

            WHERE ci.id_categoria = %s
              AND ci.id_usuario = %s

            GROUP BY ci.id_item
            ORDER BY ci.nome_item
        """, (id_categoria, id_usuario))

        return {
            "sucesso": True,
            "dados": cur.fetchall()
        }

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


# EDITAR ITEM (PUT) -com validação de reserva

@router.put("/itens/{id_item}")
def editar_item(
    id_item: int,
    id_usuario: int = Form(...),
    nome: str = Form(...),
    abreviacao: str = Form(""),
    quantidade_total: int = Form(...)
):
    nome = _strip(nome)
    abreviacao = _strip(abreviacao)

    if not nome:
        raise HTTPException(400, "Nome inválido")

    con = get_connection()
    cur = con.cursor()
    try:
        # garante que item existe
        if not _item_existe(cur, id_usuario, id_item):
            raise HTTPException(404, "Item não encontrado")

        # impede baixar estoque abaixo do que já esta reservado
        reservado = _quantidade_reservada_em_eventos(cur, id_usuario, id_item)
        if int(quantidade_total) < reservado:
            raise HTTPException(
                400,
                f"Quantidade total não pode ser menor que o reservado ({reservado}) em eventos agendados/ativos"
            )

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


# EXCLUIR ITEM (DELETE) - com proteção de item em uso
@router.delete("/itens/{id_item}")
def excluir_item(
    id_item: int,
    id_usuario: int = Query(...)
):
    con = get_connection()
    cur = con.cursor()
    try:
        # impede excluir item que está reservado/em uso em eventos agendados/ativos
        reservado = _quantidade_reservada_em_eventos(cur, id_usuario, id_item)
        if reservado > 0:
            raise HTTPException(
                400,
                f"Não é possível excluir: item está em uso/reservado ({reservado}) em eventos agendados/ativos"
            )

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


@router.get("/imagens/itens/{id_item}")
def imagem_item(
    id_item: int,
    id_usuario: int
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


@router.get("/itens/arquivo/{id_item}")
def imagem_item_arquivo(id_item: int, id_usuario: int = Query(...)):
    """
    Serve imagem de item priorizando o banco (BLOB) e com fallback para filesystem.
    """
    con = get_connection()
    cur = con.cursor()
    try:
        cur.execute("""
            SELECT imagem
            FROM catalogo_itens
            WHERE id_item=%s AND id_usuario=%s
        """, (id_item, id_usuario))

        row = cur.fetchone()
        if row and row[0]:
            return Response(content=row[0], media_type="image/*")
    finally:
        cur.close()
        con.close()

    path = f"uploads/itens/{id_usuario}/{id_item}.jpg"
    if not os.path.exists(path):
        raise HTTPException(status_code=404, detail="Imagem não encontrada")

    media_type = mimetypes.guess_type(path)[0] or "application/octet-stream"
    return FileResponse(path, media_type=media_type)


def _gerar_pdf_categoria_core(id_usuario: int, id_categoria: int):
    con = get_connection()
    cur = con.cursor(dictionary=True)

    # Empresa (opcional)
    cur.execute("SELECT nome_empresa FROM usuarios WHERE id_usuario=%s", (id_usuario,))
    usuario = cur.fetchone()
    nome_empresa = (usuario or {}).get("nome_empresa") or "Minha Empresa"

    # Categoria do usuário
    cur.execute("""
        SELECT nome_categoria
        FROM catalogo_categorias
        WHERE id_categoria=%s AND id_usuario=%s
    """, (id_categoria, id_usuario))
    categoria = cur.fetchone()
    if not categoria:
        cur.close()
        con.close()
        raise HTTPException(404, "Categoria não encontrada para este usuário")

    # Itens da categoria
    cur.execute("""
        SELECT nome_item, quantidade_total, imagem
        FROM catalogo_itens
        WHERE id_categoria=%s AND id_usuario=%s
        ORDER BY nome_item
    """, (id_categoria, id_usuario))
    itens = cur.fetchall()

    cur.close()
    con.close()

    # PDF
    temp = tempfile.NamedTemporaryFile(delete=False, suffix=".pdf")
    c = canvas.Canvas(temp.name, pagesize=A4)

    largura, altura = A4
    margem = 40
    y = altura - 70

    # Cabeçalho
    c.setFont("Helvetica-Bold", 22)
    c.drawCentredString(largura / 2, y, nome_empresa)
    y -= 34

    c.setFont("Helvetica-Bold", 14)
    c.drawCentredString(largura / 2, y, f"CATÁLOGO - {categoria['nome_categoria'].upper()}")
    y -= 18

    c.setFont("Helvetica", 11)
    c.drawCentredString(largura / 2, y, datetime.now().strftime("%d/%m/%Y"))
    y -= 22

    c.setStrokeColor(colors.grey)
    c.line(margem, y, largura - margem, y)
    y -= 22

    # Grid 2 colunas
    coluna_largura = (largura - 2 * margem) / 2
    bloco_altura = 120
    x_positions = [margem, margem + coluna_largura]

    col = 0

    for item in itens:
        if y < 140:
            c.showPage()
            y = altura - 70
            col = 0

        x = x_positions[col]

        # Cartão
        c.setFillColorRGB(0.965, 0.965, 0.965)
        c.roundRect(x, y - bloco_altura + 10, coluna_largura - 10, bloco_altura - 20, 10, fill=1, stroke=0)
        c.setFillColor(colors.black)

        # Imagem (blindada)
        img_x = x + 12
        img_y = y - 92
        img_w = 70
        img_h = 70

        desenhou = False
        try:
            if item.get("imagem"):
                image_stream = io.BytesIO(item["imagem"])
                image = ImageReader(image_stream)
                c.drawImage(image, img_x, img_y, width=img_w, height=img_h, preserveAspectRatio=True, mask='auto')
                desenhou = True
        except Exception:
            desenhou = False

        if not desenhou:
            c.setStrokeColor(colors.lightgrey)
            c.rect(img_x, img_y, img_w, img_h, stroke=1, fill=0)
            c.setStrokeColor(colors.black)

        # Texto
        c.setFont("Helvetica-Bold", 12)
        c.drawString(x + 95, y - 35, (item.get("nome_item") or "")[:40])

        c.setFont("Helvetica", 11)
        c.drawString(x + 95, y - 55, f"Quantidade: {item.get('quantidade_total', 0)}")

        col += 1
        if col == 2:
            col = 0
            y -= bloco_altura

    c.save()

    safe_nome = categoria["nome_categoria"].strip().replace(" ", "_")
    return FileResponse(
        temp.name,
        media_type="application/pdf",
        filename=f"catalogo_{safe_nome}.pdf"
    )


@router.get("/categorias/{id_categoria}/pdf")
def gerar_pdf_categoria(id_usuario: int, id_categoria: int):
    return _gerar_pdf_categoria_core(id_usuario=id_usuario, id_categoria=id_categoria)


@router.get("/categorias/{id_usuario}/{id_categoria}/pdf")
def gerar_pdf_categoria_v2(id_usuario: int, id_categoria: int):
    return _gerar_pdf_categoria_core(id_usuario=id_usuario, id_categoria=id_categoria)
