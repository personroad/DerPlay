#!/usr/bin/env python3
"""Generated, non-MFi temporary certificates; no private fixture in the repo."""
import pathlib, platform, subprocess, tempfile
ROOT=pathlib.Path(__file__).resolve().parents[2]

def run(*args):
    subprocess.run(args, cwd=ROOT, check=True, stdout=subprocess.PIPE if args[0]=='openssl' else None, stderr=subprocess.PIPE if args[0]=='openssl' else None)

def tlv(tag, body):
    length=len(body)
    if length < 128: size=bytes([length])
    else:
        n=(length.bit_length()+7)//8
        size=bytes([128|n])+length.to_bytes(n,'big')
    return bytes([tag])+size+body

def read(data, off):
    tag, size=data[off:off+2]; off+=2
    if size>=128:
        n=size&127; size=int.from_bytes(data[off:off+n],'big'); off+=n
    return tag,data[off:off+size],off+size

def fields(data):
    off=0; out=[]
    while off<len(data):
        tag,body,off=read(data,off); out.append((tag,body))
    return out

with tempfile.TemporaryDirectory(prefix='derplay-test-identity-') as tmp:
    d=pathlib.Path(tmp)
    key, other, cert, leaf, chain, pk8, min8, other8=[str(d/n) for n in ('key.pem','other.pem','cert.pem','leaf.der','chain.der','key.der','minimal.der','other.der')]
    for filename in (key,other): run('openssl','ecparam','-name','prime256v1','-genkey','-noout','-out',filename)
    run('openssl','req','-new','-x509','-key',key,'-out',cert,'-subj','/CN=DerPlay Synthetic Test Only','-days','1')
    run('openssl','x509','-in',cert,'-outform','DER','-out',leaf)
    run('openssl','crl2pkcs7','-nocrl','-certfile',cert,'-outform','DER','-out',chain)
    for src,dst in ((key,pk8),(other,other8)):
        run('openssl','pkcs8','-topk8','-nocrypt','-in',src,'-outform','DER','-out',dst)
    # Re-encode the standard inner SEC1 fields without the optional public point.
    outer=fields(read(pathlib.Path(pk8).read_bytes(),0)[1]); inner=fields(read(outer[2][1],0)[1]); outer[2]=(4,tlv(48,b''.join(tlv(t,b) for t,b in inner[:2])))
    pathlib.Path(min8).write_bytes(tlv(48,b''.join(tlv(t,b) for t,b in outer[:3])))
    binary=str(d/'der-smoke')
    run('swiftc','-swift-version','5','App/DerPlayIdentityDER.swift','Tools/derplay/IdentityDERSmoke.swift','-o',binary)
    run(binary,chain,leaf,pk8,min8)
    if platform.system()=='Darwin':
        binary=str(d/'import-smoke')
        run('swiftc','-swift-version','5','App/DerPlayIdentityDER.swift','App/DerPlayIdentityImport.swift','Sources/TDSCarKitCore/AccessoryIdentity.swift','Sources/TDSCarKitCore/Binary.swift','Sources/TDSCarKitCore/Localization.swift','Tools/derplay/IdentityImportSmoke.swift','-o',binary)
        run(binary,chain,leaf,pk8,min8,other8)
    else:
        print('Apple Security/CryptoKit identity import smoke: NOT RUN (macOS required)')
