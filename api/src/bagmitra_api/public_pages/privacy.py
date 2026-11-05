"""Privacy policy text (Marathi first, English), built on docs/legal/DATA_INVENTORY.md.

Every statement here must match the code; items that depend on the live configuration are
marked "if turned on". The 30-day deletion window and the contact setting are defaults
(OPEN_QUESTIONS Q50-Q52). Change the text and LAST_UPDATED together.
"""

from __future__ import annotations

from html import escape

LAST_UPDATED = {"mr": "५ नोव्हेंबर २०२६", "en": "5 November 2026"}
DELETION_DAYS = {"mr": "३० दिवसांत", "en": "within 30 days"}

_IF = {"mr": "चालू केले असल्यास", "en": "if turned on"}


def _if(lang: str) -> str:
    return f'<span class="if">{_IF[lang]}</span>'


def contact_line(lang: str, email: str) -> str:
    if email:
        safe = escape(email)
        label = "ईमेल" if lang == "mr" else "Email"
        return f'<p>{label}: <a href="mailto:{safe}">{safe}</a></p>'
    if lang == "mr":
        return "<p>गोपनीयतेसाठीचा संपर्क ईमेल अजून इथे प्रसिद्ध केलेला नाही; तो लवकरच याच पानावर दिसेल.</p>"
    return (
        "<p>The privacy contact email is not published here yet; it will appear on this page.</p>"
    )


def _mr(email: str) -> str:
    i = _if("mr")
    return f"""
<h2 id="mr-about">१. हे धोरण कशाबद्दल</h2>
<p>बागमित्र हे संत्रा आणि मोसंबी बागायतदारांसाठी बागेच्या नोंदींचे ॲप आहे. हे धोरण ॲप आणि
त्याचा सर्व्हर तुमची कोणती माहिती घेतात, ती कुठे ठेवतात, कोणाला जाते आणि तुमचे हक्क काय
आहेत ते सांगते. हे भारताच्या डिजिटल वैयक्तिक डेटा संरक्षण कायदा २०२३ (DPDP) नुसार आहे.</p>

<h2 id="mr-collect">२. आम्ही कोणती माहिती घेतो आणि का</h2>
<h3>खाते</h3>
<ul><li>मोबाइल नंबर (OTP ने लॉगिन) किंवा Google खाते. लॉगिन Supabase Auth करते; Google लॉगिनमध्ये
Google त्याच्या संमती-पानावर दाखवलेली माहिती (उदा. नाव, ईमेल) Supabase Auth ला देते. बागमित्रचा
सर्व्हर फक्त खात्याचा ओळख-क्रमांक आणि (असल्यास) मोबाइल नंबर वापरतो.</li></ul>
<h3>प्रोफाइल</h3>
<ul><li>नाव, भाषा, गाव, तालुका, जिल्हा, संपर्क नंबर (ऐच्छिक), आणि तुमच्या संमती: नोंदी साठवण्याची
संमती आणि WhatsApp सूचनांची संमती (ऐच्छिक). बागमित्र अजून WhatsApp संदेश पाठवत नाही; तुमची
निवड फक्त साठवली जाते.</li>
<li>जिल्हा आणि बागांचे पीक व क्षेत्र वापरून सरकारी सूचना तुमच्यासाठी निवडल्या जातात.</li></ul>
<h3>बागेच्या नोंदी (तुम्ही लिहिता त्या)</h3>
<ul><li>बाग: नाव, पीक, जात, क्षेत्र, झाडे, अंतर, सिंचन, पाण्याचा स्रोत, माती, बागेचे ठिकाण (GPS
बिंदू) आणि सीमा.</li>
<li>बहार, कामे व आठवणी, फवारणी, खते, पाणी, काढणी, मजूर (मजुराचे नाव, मजुरी, उचल), खर्च,
विक्री (व्यापाऱ्याचे नाव, वजन, दर, पैसे मिळाले का), पाहणी नोंदी, पीक विमा नोंद (विमा कंपनी,
पॉलिसी क्रमांक, रक्कम), माती/पाणी/पान तपासणीचे आकडे.</li>
<li>का: ॲप चालवण्यासाठी, तुमच्या दुसऱ्या फोनवर नोंदी दिसण्यासाठी आणि बॅकअपसाठी.</li></ul>
<h3>फोटो आणि फाइल</h3>
<ul><li>पाहणीचे फोटो फोनवरच राहतात. फोटो बॅकअप {i}: ते खाजगी Supabase Storage मध्ये
जातात (Wi-Fi वर; तुम्ही निवडल्यास मोबाइल डेटावरही) आणि काही मिनिटांत संपणाऱ्या दुव्यानेच
उघडतात.</li>
<li>पीक-नुकसान दाव्याचे फोटो, टिपा आणि तपासणी अहवालाच्या फाइल फक्त फोनवरच राहतात.</li></ul>
<h3>ठिकाण (location)</h3>
<ul><li>फक्त तुम्ही बागेचे ठिकाण/सीमा नोंदवता किंवा दाव्याचा फोटो जोडता तेव्हा एकदाच वाचले
जाते. पार्श्वभूमीत ठिकाण पाहिले जात नाही.</li></ul>
<h3>आवाज</h3>
<ul><li>आवाजाने लिहिताना फोनची स्वतःची बोलणे-ओळख सेवा (बहुतेक Android फोनवर Google ची) आवाजाचे
अक्षरात रूपांतर करते; ती सेवा तिच्या नियमांनुसार आवाज ऑनलाइन प्रक्रिया करू शकते. बागमित्रच्या
सर्व्हरला आवाज मिळत नाही. मोठ्याने वाचणे फोनवरच होते.</li></ul>
<h3>इतर</h3>
<ul><li>"संदेश तपासा": चिकटवलेला मजकूर अधिकृत सूचनांशी जुळवण्यासाठी सर्व्हरला जातो आणि कुठेही
साठवला जात नाही; फक्त त्याची लांबी आणि निकाल log मध्ये नोंदतो.</li>
<li>सरकारी सूचना पाहिली / बाजूला केली / आठवण हवी, आणि सूचना-वेळेच्या पसंती.</li>
<li>Push सूचना {i}: फोनचा push token (Firebase Cloud Messaging). सध्या हे चालू नाही;
आठवणी फोनवरच ठरतात.</li>
<li>सर्व्हर log: प्रत्येक विनंतीची वेळ, पत्ता (IP), मार्ग आणि निकाल — सुरक्षा आणि अडचणी
शोधण्यासाठी. नोंदींचा मजकूर log मध्ये नसतो. त्रुटी अहवाल सेवा (Sentry) {i}: त्रुटींची
माहिती तिथे जाते.</li>
<li>फोनवरचा छोटा log फोनवरच राहतो; तुम्ही "Logs पाठवा" दाबल्यासच तुम्ही निवडलेल्या ॲपने
जातो.</li>
<li>योजना (plan) आणि तिची मुदत. बागमित्र कार्ड किंवा बँक तपशील घेत नाही.</li></ul>

<h2 id="mr-where">३. माहिती कुठे ठेवली जाते</h2>
<ul><li>तुमच्या फोनवर (ॲप ऑफलाइन चालते).</li>
<li>Supabase चा डेटाबेस (PostgreSQL) — आमच्या सेटअप मार्गदर्शकानुसार मुंबई (ap-south-1) भागात.
सर्व्हरवरचा स्वतंत्र डेटाबेस {i}: बागमित्रच्या भाड्याच्या सर्व्हरवर (VPS), Supabase ऐवजी.</li>
<li>फोटो बॅकअप {i}: खाजगी Supabase Storage.</li></ul>

<h2 id="mr-share">४. माहिती कोणाला जाते</h2>
<p>आम्ही तुमची माहिती विकत नाही आणि जाहिरातींसाठी वापरत नाही. फक्त या सेवा आमच्यासाठी काम
करतात:</p>
<ul><li><b>Supabase</b>: लॉगिन, डेटाबेस, फोटो साठवण.</li>
<li><b>SMS सेवा</b> (Supabase मध्ये निवडलेली): OTP पाठवण्यासाठी तुमचा नंबर.</li>
<li><b>Google</b>: Google लॉगिन (तुम्ही निवडल्यास); फोनची बोलणे-ओळख; push {i}.</li>
<li><b>Open-Meteo</b>: हवामानासाठी बागेचे ठिकाण सुमारे १ किमी पर्यंत गोल करून पाठवले जाते; नाव
किंवा नंबर नाही.</li>
<li><b>data.gov.in</b> (Agmarknet): बाजारभाव आणण्यासाठी फक्त पिकाचे नाव; तुमची माहिती नाही.</li>
<li><b>Anthropic</b> (AI सारांश) {i}: फक्त सरकारी GR/परिपत्रकाचा मजकूर; शेतकऱ्याची माहिती
नाही.</li>
<li><b>Sentry</b> {i}: त्रुटी अहवाल. <b>सर्व्हर भाड्याने देणारी कंपनी</b>: API चालवण्यासाठी.</li>
<li>कायद्याने बंधनकारक असल्यासच सरकारी यंत्रणांना.</li></ul>

<h2 id="mr-keep">५. किती काळ ठेवतो</h2>
<ul><li>खाते चालू आहे तोपर्यंत. ॲपमध्ये नोंद काढल्यावर सर्व्हर ती "काढलेली" म्हणून खूण ठेवतो (इतर
फोनवरूनही ती जावी म्हणून) आणि sync साठी बदलांचा इतिहास ठेवतो.</li>
<li>खाते काढण्याची विनंती आल्यावर खाते, सर्व्हरवरच्या नोंदी, फोटो, खुणा आणि इतिहास
{DELETION_DAYS["mr"]} पुसले जातात. होस्टिंग सेवेच्या डेटाबेस बॅकअपमधील प्रत त्यांच्या मुदतीनंतर
संपते.</li>
<li>Sign out केल्यावर नोंदी फोनवर राहतात; त्याच फोनवर दुसरे खाते सुरू केल्यास (सर्व नोंदी
पाठवून झाल्या असतील तर) आधीच्या खात्याच्या नोंदी आणि फोटो फोनवरून काढले जातात.</li></ul>

<h2 id="mr-rights">६. तुमचे हक्क</h2>
<ul><li><b>पाहणे:</b> तुमच्या सर्व नोंदी ॲपमध्ये दिसतात; हिशोब CSV आणि अहवाल PDF म्हणून शेअर
करता येतात. सर्व्हरवरच्या माहितीची प्रत ईमेलने मागता येते.</li>
<li><b>दुरुस्ती:</b> ॲपमध्ये नोंद आणि प्रोफाइल बदला.</li>
<li><b>पुसणे:</b> खाली दिलेल्या पद्धतीने विनंती करा.</li>
<li><b>संमती मागे घेणे:</b> WhatsApp संमती प्रोफाइलमध्ये बंद करता येते. नोंदी साठवण्याची संमती
ॲप चालण्यासाठी लागते; ती मागे घ्यायची असल्यास खाते पुसण्याची विनंती करा.</li>
<li><b>तक्रार आणि नामनिर्देशन:</b> तक्रार किंवा तुमच्या वतीने हक्क वापरणारी व्यक्ती नेमण्यासाठी
आम्हाला लिहा. समाधान न झाल्यास भारताच्या डेटा संरक्षण मंडळाकडे (Data Protection Board of India)
तक्रार करता येते.</li></ul>

<h2 id="mr-delete">७. खाते आणि माहिती पुसण्याची विनंती</h2>
<p>खालील संपर्कावर लिहा: लॉगिनचा मोबाइल नंबर किंवा Google ईमेल द्या. आम्ही खात्री करून
{DELETION_DAYS["mr"]} खाते आणि सर्व्हरवरची माहिती पुसतो आणि तसे कळवतो. फोनवरची माहिती ॲप
uninstall केल्यावर जाते.</p>

<h2 id="mr-children">८. मुले</h2>
<p>बागमित्र प्रौढ बागायतदारांसाठी आहे; १८ वर्षांखालील मुलांसाठी नाही. मुलाची माहिती नोंदली
गेली असल्यास कळवा, आम्ही ती पुसू.</p>

<h2 id="mr-security">९. सुरक्षा</h2>
<ul><li>ॲप आणि सर्व्हरमधील सर्व संवाद HTTPS ने. प्रत्येक विनंतीचा लॉगिन token तपासला जातो.</li>
<li>प्रत्येक खाते फक्त स्वतःच्या नोंदी पाहू/बदलू शकते (सर्व्हर कोडमध्ये आणि डेटाबेसच्या
row-level security ने).</li>
<li>फोटो खाजगी साठवणीत, थोड्या वेळासाठीच्या दुव्यांनी. सर्व्हरच्या गुप्त चाव्या ॲपमध्ये नसतात.</li></ul>

<h2 id="mr-changes">१०. बदल</h2>
<p>हे धोरण बदलल्यास नवीन मजकूर आणि "शेवटचा बदल" तारीख याच पानावर दिसेल.</p>

<h2 id="mr-contact">११. संपर्क</h2>
{contact_line("mr", email)}
<p class="note">शेवटचा बदल: {LAST_UPDATED["mr"]}</p>
"""


def _en(email: str) -> str:
    i = _if("en")
    return f"""
<h2 id="en-about">1. About this policy</h2>
<p>BagMitra is an orchard record app for santra (orange) and mosambi (sweet lime) growers. This
policy explains what the app and its server collect, where it is stored, who receives it and
what your rights are, following India's Digital Personal Data Protection Act, 2023 (DPDP).</p>

<h2 id="en-collect">2. What we collect and why</h2>
<h3>Account</h3>
<ul><li>Your mobile number (sign-in by OTP) or your Google account. Sign-in is handled by Supabase
Auth; with Google sign-in, Google shares the details shown on its consent screen (such as name
and email) with Supabase Auth. BagMitra's server uses only the account id and, if present, the
mobile number.</li></ul>
<h3>Profile</h3>
<ul><li>Name, language, village, taluka, district, an optional contact number, and your consents:
storing your records, and (optional) WhatsApp reminders. BagMitra does not send WhatsApp messages
yet; your choice is only saved.</li>
<li>Your district and your plots' crop and area are used to pick the government notices meant
for you.</li></ul>
<h3>Orchard records (what you enter)</h3>
<ul><li>Plots: name, crop, variety, area, trees, spacing, irrigation, water source, soil, the plot
location (a GPS point) and boundary.</li>
<li>Bahar cycles, tasks and reminders, sprays, fertiliser inputs, irrigation, harvest, labour
(worker name, wage, advance), expenses, sales (buyer name, quantity, rate, payment status),
scouting notes, crop insurance policy (insurer, policy number, amounts), soil / water / leaf
test values.</li>
<li>Why: to run the app, show your records on your other phones, and keep a backup.</li></ul>
<h3>Photos and files</h3>
<ul><li>Scouting photos stay on your phone. Photo backup {i}: they are uploaded to a private
Supabase Storage bucket (on Wi-Fi, or on mobile data if you allow it) and opened only through
links that expire within minutes.</li>
<li>Crop-loss claim photos and notes, and lab report files, stay on your phone only.</li></ul>
<h3>Location</h3>
<ul><li>Read once, only when you mark a plot location or boundary or add a claim photo. There is
no background tracking.</li></ul>
<h3>Voice</h3>
<ul><li>Voice typing uses your phone's own speech service (on most Android phones, Google's),
which may process the audio online under its own terms. BagMitra's server never receives audio.
Reading aloud happens on the phone.</li></ul>
<h3>Other</h3>
<ul><li>"Check a message": the pasted text is sent to our server to compare with official
notices and is not stored anywhere; only its length and the result are logged.</li>
<li>Which government notices you saw, dismissed or asked to be reminded of, and your
notification preferences.</li>
<li>Push alerts {i}: your phone's push token (Firebase Cloud Messaging). Not active yet;
reminders are scheduled on the phone.</li>
<li>Server logs: time, address (IP), path and result of each request, for security and
troubleshooting. They do not contain your record contents. Error reporting (Sentry) {i}:
receives error details.</li>
<li>A small log on the phone stays there unless you tap "Send logs" and pick an app.</li>
<li>Your plan and its period. BagMitra does not collect card or bank details.</li></ul>

<h2 id="en-where">3. Where it is stored</h2>
<ul><li>On your phone (the app works offline).</li>
<li>In a Supabase PostgreSQL database, in the Mumbai (ap-south-1) region per our setup guide. The
server's own database {i}: on BagMitra's rented server (VPS) instead.</li>
<li>Photo backup {i}: private Supabase Storage.</li></ul>

<h2 id="en-share">4. Who receives it</h2>
<p>We do not sell your data or use it for advertising. Only these services process it for us:</p>
<ul><li><b>Supabase</b>: sign-in, database, photo storage.</li>
<li><b>SMS provider</b> (chosen in Supabase): your number, to send the OTP.</li>
<li><b>Google</b>: Google sign-in (if you choose it); the phone's speech service; push {i}.</li>
<li><b>Open-Meteo</b>: for weather, the plot location rounded to about 1 km; no name or
number.</li>
<li><b>data.gov.in</b> (Agmarknet): only crop names, to fetch mandi prices; none of your
data.</li>
<li><b>Anthropic</b> (AI summaries) {i}: only the text of government GRs and circulars; no
grower data.</li>
<li><b>Sentry</b> {i}: error reports. <b>The server hosting company</b>: to run the API.</li>
<li>Government authorities only where the law requires it.</li></ul>

<h2 id="en-keep">5. How long we keep it</h2>
<ul><li>While your account is active. When you delete a record in the app, the server keeps a
"deleted" mark (so it disappears from your other phones too) and a history of changes used for
sync.</li>
<li>On a deletion request, your account, server records, photos, marks and history are erased
{DELETION_DAYS["en"]}. Copies in the hosting service's database backups expire on their own
schedule.</li>
<li>Signing out keeps the records on the phone. If another account signs in on the same phone
(after everything was sent), the previous account's records and photos are removed from the
phone.</li></ul>

<h2 id="en-rights">6. Your rights</h2>
<ul><li><b>Access:</b> all your records are visible in the app; accounts can be shared as CSV and
reports as PDF. You can ask by email for a copy of what the server holds.</li>
<li><b>Correction:</b> edit records and your profile in the app.</li>
<li><b>Erasure:</b> ask as described below.</li>
<li><b>Withdrawing consent:</b> turn off the WhatsApp consent in Profile. Consent to store
records is needed for the app to work; to withdraw it, ask for your account to be deleted.</li>
<li><b>Grievance and nomination:</b> write to us to raise a grievance or to nominate a person to
exercise your rights. If not resolved, you may complain to the Data Protection Board of
India.</li></ul>

<h2 id="en-delete">7. How to ask for deletion</h2>
<p>Write to the contact below with the mobile number or Google email you sign in with. After
confirming it is you, we erase the account and its server data {DELETION_DAYS["en"]} and tell
you. Data on the phone is removed when you uninstall the app.</p>

<h2 id="en-children">8. Children</h2>
<p>BagMitra is meant for adult growers, not for children under 18. If a child's data was
entered, tell us and we will delete it.</p>

<h2 id="en-security">9. Security</h2>
<ul><li>All traffic between the app and the server uses HTTPS; every request's sign-in token is
verified.</li>
<li>Each account can read and change only its own records (in the server code and by database
row-level security).</li>
<li>Photos are in private storage behind short-lived links. Server secrets are never in the
app.</li></ul>

<h2 id="en-changes">10. Changes</h2>
<p>If this policy changes, the new text and its "last updated" date appear on this page.</p>

<h2 id="en-contact">11. Contact</h2>
{contact_line("en", email)}
<p class="note">Last updated: {LAST_UPDATED["en"]}</p>
"""


def section(lang: str, email: str) -> str:
    """One language's full policy as a `<section>` (anchor `#mr` or `#en`)."""
    body = _mr(email) if lang == "mr" else _en(email)
    return f'<section id="{lang}" lang="{lang}">{body}</section>'
