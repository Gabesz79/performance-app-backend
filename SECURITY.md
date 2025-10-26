# Security Policy

## Támogatott verziók
A fejlesztés aktívan a `main` ágon és a legfrissebb kiadásokon történik. Kérjük, lehetőség szerint mindig a legújabb verziót használd.

## Sérülékenység bejelentése

**Kérjük, NE nyiss nyilvános issue-t biztonsági jellegű hibára.** Ehelyett:

1. Hozz létre **privát Security Advisoryt** a GitHubon a repo *Security → Advisories* menüpontjában.  
   - Írd le röviden a problémát, a reprodukció lépéseit és a lehetséges hatást.
   - Ha van PoC, csatold *minimális* formában (ne tartalmazzon érzékeny adatot).
2. Ha nem tudsz Advisoryt nyitni, vedd fel a kapcsolatot a karbantartóval a GitHub profilján keresztül (pl. `@Gabesz79`) **privát csatornán**.
3. Titkok/jelszavak felfedezése esetén **azonnal** jelezd privát csatornán, és *ne publikáld* semmilyen formában.

A bejelentéseket bizalmasan kezeljük, és ésszerű időn belül visszajelzést adunk a következőkről:
- befogadás és reprodukció státusza,
- érintett verziók és kockázati besorolás,
- tervezett javítási ütemterv,
- koordinált közzététel részletei (ha releváns).

## Jó gyakorlatok a hozzájárulásoknál
- Ne commitolj **credentialeket**, `.env` fájlokat, privát kulcsokat vagy érzékeny logokat.
- Logolásnál kerüld a személyes/érzékeny adatok rögzítését.
- Függőségfrissítésekhez használd a Dependabot PR-eket (ha elérhető).
- Potenciális security-impact esetén jelöld a PR-ban (pl. `security` label).

## Licenc és felelősség
A projekt a repository gyökérben található licencfeltételek szerint használható. A közreműködők kötelesek betartani a **CODE_OF_CONDUCT.md**-et és a jelen biztonsági irányelveket.
