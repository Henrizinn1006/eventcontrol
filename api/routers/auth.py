from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr
from datetime import datetime, timedelta
import random
import smtplib
from email.mime.text import MIMEText
import bcrypt
import os

from db import get_connection

router = APIRouter()

class Cadastro(BaseModel):
    nome: str
    email: EmailStr
    senha: str
    confirmar_senha: str

class Login(BaseModel):
    email: EmailStr
    senha: str

class RecuperarSenha(BaseModel):
    email: EmailStr

class ValidarCodigo(BaseModel):
    email: EmailStr
    codigo: str

class NovaSenha(BaseModel):
    email: EmailStr
    codigo: str
    nova_senha: str
    confirmar_senha: str

def hash_senha(senha: str) -> str:
    return bcrypt.hashpw(senha.encode(), bcrypt.gensalt()).decode()

def verificar_senha(senha: str, senha_hash: str) -> bool:
    return bcrypt.checkpw(senha.encode(), senha_hash.encode())

def enviar_email_codigo(destinatario: str, codigo: str):
    """
    Recomendado colocar essas variáveis no .env:
    EMAIL_FROM=seuemail@gmail.com
    EMAIL_APP_PASSWORD=sua_senha_de_app_google
    """
    remetente = os.getenv("EMAIL_FROM", "eventmaster78@gmail.com")
    senha_email = os.getenv("EMAIL_APP_PASSWORD", "tadi gnsd znjd cxxn")

    corpo = f"""Olá!

Seu código de recuperação de senha é:

{codigo}

Ele expira em 15 minutos.

Equipe EventControl
"""

    msg = MIMEText(corpo)
    msg["Subject"] = "Recuperação de Senha - EventControl"
    msg["From"] = remetente
    msg["To"] = destinatario

    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as smtp:
        smtp.login(remetente, senha_email)
        smtp.send_message(msg)

@router.post("/cadastro")
def cadastrar(dados: Cadastro):
    if dados.senha != dados.confirmar_senha:
        raise HTTPException(400, "As senhas não coincidem")

    con = get_connection()
    cur = con.cursor(dictionary=True)

    cur.execute("SELECT id_usuario FROM usuarios WHERE email=%s", (dados.email,))
    if cur.fetchone():
        cur.close(); con.close()
        raise HTTPException(400, "Email já cadastrado")

    cur.execute(
        "INSERT INTO usuarios (nome, email, senha_hash) VALUES (%s, %s, %s)",
        (dados.nome, dados.email, hash_senha(dados.senha))
    )
    con.commit()
    cur.close(); con.close()
    return {"mensagem": "Usuário cadastrado com sucesso"}

@router.post("/login")
def login(dados: Login):
    con = get_connection()
    cur = con.cursor(dictionary=True)

    cur.execute("SELECT * FROM usuarios WHERE email=%s", (dados.email,))
    usuario = cur.fetchone()

    cur.close(); con.close()

    if not usuario or not verificar_senha(dados.senha, usuario["senha_hash"]):
        raise HTTPException(401, "Credenciais inválidas")

    return {"id_usuario": usuario["id_usuario"], "nome": usuario["nome"], "email": usuario["email"]}

@router.post("/recuperar-senha")
def recuperar_senha(dados: RecuperarSenha):
    codigo = str(random.randint(100000, 999999))
    validade = datetime.now() + timedelta(minutes=15)

    con = get_connection()
    cur = con.cursor()

    cur.execute("""
        UPDATE usuarios
        SET codigo_recuperacao=%s, expira_em=%s
        WHERE email=%s
    """, (codigo, validade, dados.email))

    if cur.rowcount == 0:
        cur.close(); con.close()
        raise HTTPException(404, "Email não encontrado")

    con.commit()
    cur.close(); con.close()

    enviar_email_codigo(dados.email, codigo)
    return {"mensagem": "Código enviado por email"}

@router.post("/validar-codigo")
def validar_codigo(dados: ValidarCodigo):
    con = get_connection()
    cur = con.cursor(dictionary=True)

    cur.execute("""
        SELECT codigo_recuperacao, expira_em
        FROM usuarios
        WHERE email=%s
    """, (dados.email,))

    usuario = cur.fetchone()
    cur.close(); con.close()

    if not usuario or usuario["codigo_recuperacao"] != dados.codigo:
        raise HTTPException(400, "Código inválido")

    if usuario["expira_em"] is None or usuario["expira_em"] < datetime.now():
        raise HTTPException(400, "Código expirado")

    return {"mensagem": "Código válido"}

@router.post("/nova-senha")
def nova_senha(dados: NovaSenha):
    if dados.nova_senha != dados.confirmar_senha:
        raise HTTPException(400, "As senhas não coincidem")

    con = get_connection()
    cur = con.cursor(dictionary=True)

    cur.execute("""
        SELECT id_usuario, codigo_recuperacao, expira_em
        FROM usuarios
        WHERE email=%s
    """, (dados.email,))

    usuario = cur.fetchone()

    if not usuario or usuario["codigo_recuperacao"] != dados.codigo:
        cur.close(); con.close()
        raise HTTPException(400, "Código inválido")

    if usuario["expira_em"] is None or usuario["expira_em"] < datetime.now():
        cur.close(); con.close()
        raise HTTPException(400, "Código expirado")

    cur.execute("""
        UPDATE usuarios
        SET senha_hash=%s, codigo_recuperacao=NULL, expira_em=NULL
        WHERE id_usuario=%s
    """, (hash_senha(dados.nova_senha), usuario["id_usuario"]))

    con.commit()
    cur.close(); con.close()

    return {"mensagem": "Senha alterada com sucesso"}
