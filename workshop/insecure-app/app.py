from flask import Flask, request, render_template_string, make_response
from flask_basicauth import BasicAuth
import subprocess
import os
import sqlite3
import json
import pprint

app = Flask(__name__)
app.config['BASIC_AUTH_USERNAME'] = os.environ.get('AUTH_USERNAME')
app.config['BASIC_AUTH_PASSWORD'] = os.environ.get('AUTH_PASSWORD')
basic_auth = BasicAuth(app)

@app.route('/', methods=['GET'])
def index():
    response = make_response('Nothing to see here')
    response.headers['Content-Type'] = 'text/plain'
    return response

@app.route('/crash', methods=['GET'])
def crash():
    output = "SOMETHING WENT WRONG\n\n"
    for i, l in os.environ.items():
        output += i + ':' + l + "\n"
    output += "ENV=" + str(os.environ) + "\n\n"
    output += str(request.headers) + "\n\n"
    output += str(request.endpoint) + "\n\n"
    output += str(request.method) + "\n\n"
    output += str(request.remote_addr) + "\n\n"

    response = make_response(output)
    response.headers['Content-Type'] = 'text/plain'
    return response
    

@app.route('/admin', methods=['GET', 'POST'])
@basic_auth.required
def admin():
    output = ''
    # SQL Injection?
    db = sqlite3.connect("tutorial.db")
    cursor = db.cursor()
    username = ''
    password = ''
    try:
        #the % is what makes it bad, instead of passing them in as parameters
        #Example Exploit: SELECT * FROM users WHERE username = '' OR '1'='1' AND password = '' OR '1'='1'
        cursor.execute("SELECT * FROM users WHERE username = '%s' AND password = '%s'" % (username, password))
    except:
        pass
    if request.method == 'POST':
        if 'command' in request.form:
            cmd = request.form['command']
            process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = process.communicate()
            if process.returncode == 0:
                output = stdout.decode('utf-8')
            else:
                output = f"Error (Exit Code: {process.returncode}):\n{stderr.decode('utf-8')}"
        elif 'file' in request.files:
            uploaded_file = request.files['file']
            uploaded_file.save(os.path.join('/uploads', uploaded_file.filename))
            output = f"File {uploaded_file.filename} uploaded successfully!"
        elif 'sql' in request.form:
            sql = request.form['sql']
            res = cursor.execute(sql)
            output = json.dumps(res.fetchall())


    return render_template_string("""
        <h1>Admin panel.  If your name is not Frank, you should not be here.</h1>
        <form action="/admin" method="post">
            Run a command: <input type="text" name="command">
            <input type="submit" value="Run">
        </form>
        <br>
        <form action="/admin" method="post" enctype="multipart/form-data">
            Upload a file: <input type="file" name="file">
            <input type="submit" value="Upload">
        </form>
        <br>
        <form action="/admin" method="post">
            Inject some SQL <input type="text" name="sql">
            <input type="submit" value="Run">
        </form>
        <pre>{{output}}</pre>
    """, output=output)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
