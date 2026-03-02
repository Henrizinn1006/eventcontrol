import os
print("EVENTOS.PY CARREGADO DE:", os.path.abspath(__file__))

from fastapi import APIRouter, HTTPException, Form, Body, Query
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import List
from db import get_connection
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
import tempfile


# MODELOS PYDANTIC

class DevolucaoItem(BaseModel):
    id_item: int
    qtd_devolvida: int


class FinalizarEventoBody(BaseModel):
    status: str  # "concluido" ou "cancelado"
    devolucoes: List[DevolucaoItem]


router = APIRouter()

# EVENTOS (CRUD)

@router.get("/usuario/{id_usuario}")
def listar_eventos(id_usuario: int):
    con = get_connection()
    cur = con.cursor(dictionary=True)

    try:
        cur.execute("""
            SELECT
                id_evento,
                id_usuario,
                nome_evento,
                nome_cliente,
                endereco_evento,
                data_evento,
                hora_evento,
                status,
                criado_em
            FROM eventos
            WHERE id_usuario = %s
            ORDER BY data_evento, hora_evento
        """, (id_usuario,))

        return cur.fetchall()

    finally:
        cur.close()
        con.close()


@router.post("/")
def criar_evento(
    id_usuario: int = Form(...),
    nome_evento: str = Form(...),
    nome_cliente: str = Form(None),
    endereco_evento: str = Form(None),
    data_evento: str = Form(...),
    hora_evento: str | None = Form(None),
):
    con = get_connection()
    cur = con.cursor()

    try:
        # garante que o usuário existe
        cur.execute(
            "SELECT id_usuario FROM usuarios WHERE id_usuario = %s",
            (id_usuario,)
        )
        if not cur.fetchone():
            raise HTTPException(400, "Usuário não existe")

        # created_by (FK)
        cur.execute("""
            INSERT INTO eventos
            (
                id_usuario,
                nome_evento,
                nome_cliente,
                endereco_evento,
                data_evento,
                hora_evento,
                status,
                created_by
            )
            VALUES (%s,%s,%s,%s,%s,%s,'agendado',%s)
        """, (
            id_usuario,
            nome_evento,
            nome_cliente,
            endereco_evento,
            data_evento,
            hora_evento,
            id_usuario  # created_by
        ))

        con.commit()
        return {"ok": True}

    finally:
        cur.close()
        con.close()


@router.put("/{id_evento}")
def editar_evento(
    id_usuario: int,
    id_evento: int,
    nome_evento: str,
    nome_cliente: str,
    endereco_evento: str,
    data_evento: str,
    hora_evento: str | None = None
):
    con = get_connection()
    cur = con.cursor()

    try:
        cur.execute("""
            UPDATE eventos
            SET
                nome_evento=%s,
                nome_cliente=%s,
                endereco_evento=%s,
                data_evento=%s,
                hora_evento=%s
            WHERE id_evento=%s AND id_usuario=%s
        """, (
            nome_evento,
            nome_cliente,
            endereco_evento,
            data_evento,
            hora_evento,
            id_evento,
            id_usuario
        ))

        if cur.rowcount == 0:
            raise HTTPException(404, "Evento não encontrado")

        con.commit()
        return {"ok": True}

    finally:
        cur.close()
        con.close()


@router.delete("/{id_evento}")
def excluir_evento(id_evento: int, id_usuario: int):
    con = get_connection()
    cur = con.cursor(dictionary=True)
    try:
        #  Busca itens do evento
        cur.execute("""
            SELECT id_item,
                   quantidade_locada,
                   quantidade_devolvida
            FROM itens_evento
            WHERE id_evento=%s
        """, (id_evento,))
        itens = cur.fetchall()

        # Devolve tudo ao estoque
        for item in itens:
            em_uso = item["quantidade_locada"] - item["quantidade_devolvida"]

            if em_uso > 0:
                cur.execute("""
                    UPDATE catalogo_itens
                    SET quantidade_total = quantidade_total + %s
                    WHERE id_item=%s AND id_usuario=%s
                """, (em_uso, item["id_item"], id_usuario))

        # Remove itens do evento
        cur.execute("""
            DELETE FROM itens_evento
            WHERE id_evento=%s
        """, (id_evento,))

        # Remove o evento
        cur.execute("""
            DELETE FROM eventos
            WHERE id_evento=%s AND id_usuario=%s
        """, (id_evento, id_usuario))

        con.commit()
        return {"ok": True}
    finally:
        cur.close()
        con.close()

# ITENS DO EVENTO

def _quantidade_disponivel(cur, id_usuario: int, id_item: int) -> int:
    cur.execute("""
        SELECT quantidade_total
        FROM catalogo_itens
        WHERE id_item=%s AND id_usuario=%s
    """, (id_item, id_usuario))

    item = cur.fetchone()
    if not item:
        raise HTTPException(404, "Item não encontrado")

    total = item[0]

    cur.execute("""
        SELECT COALESCE(SUM(ie.quantidade_locada - ie.quantidade_devolvida), 0)
        FROM itens_evento ie
        JOIN eventos e ON e.id_evento = ie.id_evento
        WHERE ie.id_item=%s
          AND e.id_usuario=%s
          AND e.status = 'ativo'
    """, (id_item, id_usuario))

    reservados = cur.fetchone()[0]
    return max(0, total - reservados)


@router.get("/{id_evento}/itens")
def listar_itens_evento(id_usuario: int, id_evento: int):
    print("ROTA OK:", id_evento, id_usuario)
    con = get_connection()
    cur = con.cursor(dictionary=True)

    try:
        cur.execute("""
            SELECT
                ie.id_item,
                ci.nome_item,
                ci.abreviacao,
                ie.quantidade_locada,
                ie.quantidade_devolvida
            FROM itens_evento ie
            JOIN catalogo_itens ci ON ci.id_item = ie.id_item
            JOIN eventos e ON e.id_evento = ie.id_evento
            WHERE ie.id_evento=%s AND e.id_usuario=%s
        """, (id_evento, id_usuario))

        return cur.fetchall()

    finally:
        cur.close()
        con.close()


@router.post("/{id_evento}/itens")
def adicionar_item_evento(
    id_usuario: int,
    id_evento: int,
    id_item: int,
    quantidade: int
):
    if quantidade <= 0:
        raise HTTPException(400, "Quantidade inválida")

    con = get_connection()
    cur = con.cursor()

    try:
        cur.execute("""
            SELECT status FROM eventos
            WHERE id_evento=%s AND id_usuario=%s
        """, (id_evento, id_usuario))

        ev = cur.fetchone()
        if not ev:
            raise HTTPException(404, "Evento não encontrado")
        if ev[0] in ("concluido", "cancelado"):
            raise HTTPException(400, "Evento finalizado")

        disponivel = _quantidade_disponivel(cur, id_usuario, id_item)
        if quantidade > disponivel:
            raise HTTPException(400, f"Disponível apenas {disponivel}")

        cur.execute("""
            SELECT quantidade_locada
            FROM itens_evento
            WHERE id_evento=%s AND id_item=%s
        """, (id_evento, id_item))

        row = cur.fetchone()
        if row:
            cur.execute("""
                UPDATE itens_evento
                SET quantidade_locada = quantidade_locada + %s
                WHERE id_evento=%s AND id_item=%s
            """, (quantidade, id_evento, id_item))
        else:
            cur.execute("""
                INSERT INTO itens_evento
                (id_evento, id_item, quantidade_locada, quantidade_devolvida)
                VALUES (%s,%s,%s,0)
            """, (id_evento, id_item, quantidade))

        con.commit()
        return {"ok": True}

    finally:
        cur.close()
        con.close()

# PDF

@router.get("/{id_evento}/pdf")
def gerar_pdf(
    id_evento: int,
    id_usuario: int = Query(...)
):
    con = get_connection()
    cur = con.cursor(dictionary=True)

    try:
        cur.execute("""
            SELECT
                id_evento,
                nome_evento,
                nome_cliente,
                endereco_evento,
                data_evento,
                TIME_FORMAT(hora_evento, '%H:%i') AS hora_evento,
                status
            FROM eventos
            WHERE id_evento=%s AND id_usuario=%s
        """, (id_evento, id_usuario))

        evento = cur.fetchone()
        if not evento:
            raise HTTPException(404, "Evento não encontrado")

        cur.execute("""
            SELECT
                ci.nome_item,
                ci.abreviacao,
                ie.quantidade_locada,
                ie.quantidade_devolvida
            FROM itens_evento ie
            JOIN catalogo_itens ci ON ci.id_item = ie.id_item
            WHERE ie.id_evento=%s
        """, (id_evento,))

        itens = cur.fetchall()

    finally:
        cur.close()
        con.close()

    temp = tempfile.NamedTemporaryFile(delete=False, suffix=".pdf")
    c = canvas.Canvas(temp.name, pagesize=A4)
    y = 800

    c.setFont("Helvetica-Bold", 16)
    c.drawString(50, y, f"Evento: {evento['nome_evento']}")
    y -= 25

    c.setFont("Helvetica", 12)
    c.drawString(50, y, f"Cliente: {evento['nome_cliente'] or '-'}")
    y -= 18
    c.drawString(50, y, f"Local: {evento['endereco_evento'] or '-'}")
    y -= 18
    c.drawString(50, y, f"Data: {evento['data_evento']} Hora: {evento['hora_evento'] or '-'}")
    y -= 18
    c.drawString(50, y, f"Status: {evento['status']}")
    y -= 30

    c.setFont("Helvetica-Bold", 14)
    c.drawString(50, y, "Itens")
    y -= 20

    c.setFont("Helvetica", 11)
    for it in itens:
        c.drawString(
            50, y,
            f"{it['nome_item']} ({it['abreviacao'] or ''}) - "
            f"Locado: {it['quantidade_locada']} | Devolvido: {it['quantidade_devolvida']}"
        )
        y -= 16
        if y < 80:
            c.showPage()
            y = 800

    c.save()

    return FileResponse(
        temp.name,
        media_type="application/pdf",
        filename="evento.pdf"
    )


@router.post("/{id_evento}/ativar")
def ativar_evento(id_usuario: int, id_evento: int):
    con = get_connection()
    cur = con.cursor()
    try:
        cur.execute("""
            UPDATE eventos
            SET status='ativo'
            WHERE id_evento=%s AND id_usuario=%s
        """, (id_evento, id_usuario))

        if cur.rowcount == 0:
            raise HTTPException(404, "Evento não encontrado")

        con.commit()
        return {"ok": True}
    finally:
        cur.close()
        con.close()


@router.post("/{id_evento}/finalizar")
def finalizar_evento(id_usuario: int, id_evento: int, status: str, devolucoes: str = ""):
    con = get_connection()
    cur = con.cursor()
    try:
        cur.execute("""
            UPDATE eventos
            SET status=%s
            WHERE id_evento=%s AND id_usuario=%s
        """, (status, id_evento, id_usuario))

        if cur.rowcount == 0:
            raise HTTPException(404, "Evento não encontrado")

        if devolucoes:
            for item_dev in devolucoes.split(','):
                if ':' in item_dev:
                    id_item, qtd = item_dev.split(':')
                    cur.execute("""
                        UPDATE itens_evento
                        SET quantidade_devolvida = %s
                        WHERE id_evento=%s AND id_item=%s
                    """, (int(qtd), id_evento, int(id_item)))

        con.commit()
        return {"ok": True}
    finally:
        cur.close()
        con.close()


@router.post("/{id_evento}/finalizar-json")
def finalizar_evento_json(
    id_usuario: int,
    id_evento: int,
    payload: FinalizarEventoBody = Body(...)
):
    con = get_connection()
    cur = con.cursor()

    try:
        # Confirma evento e status atual
        cur.execute("""
            SELECT status FROM eventos
            WHERE id_evento=%s AND id_usuario=%s
        """, (id_evento, id_usuario))
        ev = cur.fetchone()
        if not ev:
            raise HTTPException(404, "Evento não encontrado")

        if ev[0] in ("concluido", "cancelado"):
            raise HTTPException(400, "Evento já está finalizado")

        # Mapa do que foi locado no evento
        cur.execute("""
            SELECT id_item, quantidade_locada
            FROM itens_evento
            WHERE id_evento=%s
        """, (id_evento,))
        locados = {row[0]: int(row[1]) for row in cur.fetchall()}

        # Validação das devoluções
        for d in payload.devolucoes:
            if d.id_item not in locados:
                raise HTTPException(400, f"Item {d.id_item} não pertence ao evento")
            if d.qtd_devolvida < 0 or d.qtd_devolvida > locados[d.id_item]:
                raise HTTPException(400, f"Qtd devolvida inválida para item {d.id_item}")

        # Atualiza devolvidas e ajusta estoque por perdas
        for d in payload.devolucoes:
            qtd_locada = locados[d.id_item]
            qtd_devolvida = d.qtd_devolvida
            perdas = qtd_locada - qtd_devolvida  # o que não voltou

            # Atualiza devolvida no evento
            cur.execute("""
                UPDATE itens_evento
                SET quantidade_devolvida=%s
                WHERE id_evento=%s AND id_item=%s
            """, (qtd_devolvida, id_evento, d.id_item))

            # Se houve perda, debita do estoque do catálogo
            if perdas > 0:
                cur.execute("""
                    UPDATE catalogo_itens
                    SET quantidade_total = GREATEST(0, quantidade_total - %s)
                    WHERE id_item=%s AND id_usuario=%s
                """, (perdas, d.id_item, id_usuario))

        # Finaliza status do evento
        cur.execute("""
            UPDATE eventos
            SET status=%s
            WHERE id_evento=%s AND id_usuario=%s
        """, (payload.status, id_evento, id_usuario))

        con.commit()
        return {"ok": True}

    finally:
        cur.close()
        con.close()
