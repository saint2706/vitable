import os, json, times, strutils, docopt , httpclient, terminal

let cliversion = "0.1.1"

assert getHomeDir() == expandTilde("~")

let p10kfunc = """
function prompt_vitable() {
        ttrem=$(vitable ongoing)
        if [ ! -z "$ttrem" ]
        then
                p10k segment -b yellow -f white -t "✎ $ttrem"
        else
                p10k segment -b yellow -f white -t "✎ No ongoing classes!"
        fi
}
"""

let doc = """
__      _______ _______    _     _
\ \    / /_   _|__   __|  | |   | |
 \ \  / /  | |    | | __ _| |__ | | ___
  \ \/ /   | |    | |/ _` | '_ \| |/ _ \
   \  /   _| |_   | | (_| | |_) | |  __/
    \/   |_____|  |_|\__,_|_.__/|_|\___|

View your timetable right in your terminal!

Created with ❤️  by the Cartel Family.

Developers:
    Gagan Malvi (https://github.com/gaganmalvi)
    Vishesh Bansal (https://github.com/VisheshBansal)
    Rishabh Agrawal (https://github.com/saintwithataint)

USAGE:
    vitable (s | show | Shows all classes today)
    vitable (o | ongoing | Shows ongoing class)
    vitable (a | all | Shows full timetable)
    vitable (n | new | Add or edit Timetable)
    vitable p10k
    vitable (-h | --help)
    vitable (-v | --version)

OPTIONS:
    -h, --help          Show this screen.
    -v, --version       Show the version.
"""

proc fetchreq() =
    var ttfile = getHomeDir()
    ttfile.add("timetable.txt")
    let f = open(ttfile)
    let data = readAll(f)
    var param = "request="
    param.add(data)
    let client = newHttpClient()
    client.headers = newHttpHeaders({ "Accept":"application/json","Content-Type": "application/x-www-form-urlencoded" })
    var path = getHomeDir()
    path.add(".vitable.json")
    let response = client.request("https://vit-timetableapi.herokuapp.com/fetch/", httpMethod = HttpPost, body = $param)
    if response.status == "200 OK":
        let resp = response.body
        writeFile(path, resp)
        styledEcho styleBright, fgGreen, "The timetable has been saved successfully. Please re-run vitable -h to know the list of commands you can now use."
    else:
        styledEcho styleBright, fgRed, "Something went wrong. Please retry once again."
    f.close()

proc fetchNewTt() =
    echo "Copy your timetable from VTOP and paste it in timetable.txt, which should be placed in the home directory."
    echo "Do you want to proceed? [Y/N] "
    let ans = readLine(stdin)
    if ans=="y" or ans=="Y":
        fetchreq()

let daynow = now()
var daytoday = toUpperAscii(daynow.format("ddd"))

proc showTT() =
    try:
        var path = getHomeDir()
        path.add(".vitable.json")
        let jsonNode = parseFile(path)
        var tt = jsonNode["Slots"]
        echo "Timetable for today."
        if daytoday == "SAT" or daytoday == "SUN":
            echo "No classes for today!"
        else:
            for i in tt:
                if getStr(i["Day"]) == daytoday:
                    var
                        course = i["Course_FullName"]
                        coursecode = i["Course_Name"]
                        coursetype = i["Course_type"]
                        slot = i["Slot"]
                        intime = i["StartTime"]
                        outtime = i["EndTime"]
                    echo ""
                    echo "Course: ", getStr(course)
                    echo "Course Code: ", getStr(coursecode)
                    echo "Course Type: ", getStr(coursetype)
                    echo "Timings: ", getStr(intime), " - ", getStr(outtime)
                    echo "Slot: ", getStr(slot)
    except IOError:
        fetchNewTt()

proc showAll() =
    try:
        var path = getHomeDir()
        path.add(".vitable.json")
        let jsonNode = parseFile(path)
        var tt = jsonNode["Slots"]
        echo "Full Timetable"
        for i in tt:
            echo "Day: ",getStr(i["Day"])
            var
                course = i["Course_FullName"]
                coursecode = i["Course_Name"]
                slot = i["Slot"]
                intime = i["StartTime"]
                outtime = i["EndTime"]
            echo "Course: ", getStr(course)
            echo "Course Code: ", getStr(coursecode)
            echo "Timings: ", getStr(intime), " - ", getStr(outtime)
            echo "Slot: ", getStr(slot)
            echo ""
    except IOError:
        fetchNewTt()

proc p10kInstall() =
    echo "VITable Powerlevel10k plugin.\n"
    echo "In ~/.p10k.zsh, add the following function.\n"
    echo p10kfunc
    echo ""
    echo "Now, add the definition vitable to LEFT or RIGHT arguments, whatever you prefer.\n"
    echo "Source .zshrc, or restart your terminal."

proc classesOngoing() =
    try:
        var path = getHomeDir()
        path.add(".vitable.json")
        let jsonNode = parseFile(path)
        var tt = jsonNode["Slots"]
        if daytoday == "SAT" or daytoday == "SUN":
            echo "No classes today!"
        else:
            for f in tt:
                if getStr(f["Day"]) == daytoday:
                    var timenow = daynow.format("HH:mm")
                    var intime = getStr(f["StartTime"])
                    var outtime = getStr(f["EndTime"])
                    if timenow >= intime and timenow <= outtime:
                        echo "Current Class: ", getStr(f["Course_FullName"])
    except IOError:
        fetchNewTt()

let args = docopt(doc, version = cliversion)

if args["show"] or args["s"]:
    showTT()

if args["p10k"]:
    p10kInstall()

if args["ongoing"] or args["o"]:
    classesOngoing()

if args["all"] or args["a"]:
    showAll()

if args["new"] or args["n"]:
    fetchNewTt()
