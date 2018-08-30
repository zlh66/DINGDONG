<!--#include file="easyasp/easp.asp"-->
<!--#include file="data/Connect.asp"-->
<!--#include file="data/Function.asp"-->
<script language="jscript" runat="server">    
function getObj(str){eval("var o=" + str);return o;}
function toUTF8(str){return encodeURI(encodeURI(str));}
function isExist(key,obj){return (key in obj);}
</script>
<% 
response.charset="UTF-8"


Dim xmlCount, xmlRequest, xmlResult
xmlCount = Request.TotalBytes
If xmlCount > 0 Then
	xmlRequest = Request.BinaryRead(xmlCount)
	xmlResult = BytesToBstr(xmlRequest,"utf-8")
End IF	

'if xmlResult="" then response.end

Dim obj_sequence
Dim obj_inputtext
Dim obj_userid
Dim obj_keywords
Set obj=getObj(xmlResult)
	obj_sequence = trim(obj.sequence)'id 对话ID 一进一出(只有一对)
	obj_inputtext = trim(obj.input_text)'我对音像说的内容
	obj_userid = trim(obj.user.user_id)	'音像的应用ID
	'自定义变量
	'if isExist("slots",obj)=true then
		'if isExist("question_again",obj.slots)=true then obj_keywords = "question_again"
		'if isExist("xy_answer_next",obj.slots)=true then obj_keywords = "xy_answer_next"
		'if isExist("exit_game",obj.slots)=true then obj_keywords = "exit_game"	
		'if isExist("prepare_ready",obj.slots)=true then obj_keywords = "prepare_ready"
	'end if
Set obj=Nothing

call DingDongLog("用户",obj_inputtext,xmlResult)

'自定义关键变量事件
strAction = ""
'if obj_keywords = "question_again" then strAction = "do_repeat"
'if obj_keywords = "xy_answer_next" then strAction = "do_next"
'if obj_keywords = "exit_game" then strAction = "do_exit"
'if obj_keywords = "prepare_ready" then strAction = "do_begin"


'语音关键词
'in_arrKeyWords = "in_StrBegin,in_StrExit,in_StrNext,in_StrRepeat,in_Answer_ABC,in_Answer_AB,in_Answer_AC,in_Answer_BC,in_Answer_A,in_Answer_B,in_Answer_C"

'语音关键词----用户
in_StrBegin = "打开永修技术"
in_StrExit = "退出考试|退出|结束|关闭|再见|拜拜"
in_StrNext = "不知道|不清楚|下一题|下一个|下一道"
in_StrRepeat = "没听清|听不清|再说一遍|再来一遍|再来一次|再说一次|请重复"

'语音关键词----答案
'in_Answer_ABC = "ABC"
'in_Answer_AB = "AB|BABY"
'in_Answer_AC = "AC"
'in_Answer_BC = "BC"
'in_Answer_A = "A|哎"
'in_Answer_B = "B|必"
'in_Answer_C = "C|西"

'语音关键词----音箱
out_strBegin = "开始考试，请听题"
out_strExit = "退出考试，会话结束"
out_strRight = "回答正确"
out_strWrong = "回答错误，正确答案是：{$}"
out_strAnswerList = "可选答案"
out_strQuestionType = "本题为{$}题，请说出您的答案"
out_strListen = "请听题"
out_strListenAgin = "请重新听题"
out_strListenNext = "请听下一题"
out_StrComplete = "答题已经完毕，会话结束"
out_strUnclear  = "你说啥，我没听明白"
out_StrError = "出错了，考题准备失败"


'问题类型
strQuestionType = "多选|单选"
'答案数组
arrAnswerNo = split("A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z","|")
arrAnswerStr = split("A|哎|AB|ABB|BABY|AC|ABC|ACB|B|BA|BC|BAC|BCA|C|CA|CB|CAB|CBA","|")


talkInfo = ""
endStatus = false

if  instr(in_StrExit,obj_inputtext)>0 then

	'结束
	talkInfo = out_strExit
	endStatus = true
	'更新所有题的状态
	cnn.execute "update DingDongEaxmList set answerStatus=1 where sessionID='"&obj_userid&"'"
	
elseif  instr(in_StrBegin,obj_inputtext)>0 then
	
	'清空历史记录
	cnn.execute "update DingDongEaxmList set flag=9 where sessionID='"&obj_userid&"'"
	
	'开始考试，播第一题
	talkInfo = out_strBegin
	strsql = "select top 1 * from Question where flag=0 and datatype='train' and Dataid=7 order by sort asc"
	rs.open strsql,cnn,1,1
	if not rs.eof then
		'读问题
		talkInfo = talkInfo & "，" & rs("title")
		rightAnswerNo = ""

		if instr(strQuestionType,trim(rs("questionType"))) > 0 then
			'读答案
			talkInfo = talkInfo & "，" & out_strAnswerType	
			strsql = "select  * from Answer where flag=0 and Questionid='"&rs("id")&"'"
			rrs.open strsql,cnn,1,1
			if not rrs.eof then
				for i=1 to rrs.recordcount 
					talkInfo = talkInfo & "；" & arrAnswerNo(i-1) & "，" & rrs("title")
					if trim(rrs("istrue"))="T" then
						rightAnswerNo = rightAnswerNo & arrAnswerNo(i-1)
					end if
					rrs.movenext
				next
				talkInfo = talkInfo & "，" & replace(out_StrQuestionType,"{$}",rs("questionType"))
			else
				talkInfo = out_StrError
				endStatus = true
			end if
			rrs.close
		else
			talkInfo = talkInfo & "，" & replace(out_StrQuestionType,"{$}",rs("questionType"))
		end if
		
		call DingDongExamLog(obj_userid,rs("id"),rs("title"),talkInfo,rs("questionType"),rs("sort"),rightAnswerNo)
	else
		talkInfo = strError
		endStatus = true
	end if	rs.close

elseif  instr(in_StrRepeat,obj_inputtext)>0 then
	
	'没听清，重听
	strsql = "select top 1 * from DingDongEaxmList where flag=0 and answerStatus=0 and sessionID='"&obj_userid&"'  order by id desc "
	ors.open strsql,cnn,1,1
	if not ors.eof then
			
		'读问题
		talkInfo = out_strListenAgin
		talkInfo = talkInfo & "，" & ors("questionTitle")
		rightAnswerNo = ""

		if instr(strQuestionType,trim(ors("questionType"))) > 0 then
			'读答案
			talkInfo = talkInfo & "，" & out_strAnswerList
			strsql = "select  * from Answer where flag=0 and Questionid='"&ors("questionID")&"'"
			rrs.open strsql,cnn,1,1
			if not rrs.eof then
				for i=1 to rrs.recordcount 
					talkInfo = talkInfo & "；" & arrAnswerNo(i-1) & "，" & rrs("title")
					if trim(rrs("istrue"))="T" then
						rightAnswerNo = rightAnswerNo & arrAnswerNo(i-1)
					end if
					rrs.movenext
				next
				talkInfo = talkInfo & "，" & replace(out_StrQuestionType,"{$}",ors("questionType"))  
			else
				talkInfo = talkInfo & out_StrError
				endStatus = true
			end if
			rrs.close
		else
			talkInfo = talkInfo & "，" & replace(out_StrQuestionType,"{$}",ors("questionType")) 
		end if
			
	else
		talkInfo = out_StrComplete
		endStatus = true
	end if
	ors.close

else

	'答题：所有回答都将跳到下一题，如果不主动要求下一题，播放答题结果
	strsql = "select top 1 * from DingDongEaxmList where flag=0 and answerStatus=0 and sessionID='"&obj_userid&"'  order by id desc "
	rs.open strsql,cnn,1,1
	if not rs.eof then
		rightAnswer = Ucase(rs("rightAnswer"))
		
		'下一题 | 回答
		if   instr(in_StrNext,obj_inputtext)>0 then
			'主动下一题
			'talkInfo = out_strListenNext
		else
			userAnswer = Ucase(obj_inputtext)
			includeAnswer = ""
			for k = 0 to ubound(arrAnswerStr)
				if userAnswer = arrAnswerStr(k) then 
					includeAnswer = arrAnswerStr(k)
					exit for
				end if
			next
			
			if includeAnswer<>"" then
				if includeAnswer="ABB" and rightAnswer="AB" then
					talkInfo = out_strRight
				elseif includeAnswer="BABY" and rightAnswer="AB" then
					talkInfo = out_strRight
				elseif includeAnswer="哎" and rightAnswer="A" then
					talkInfo = out_strRight
				elseif includeAnswer = rightAnswer then
					talkInfo = out_strRight
				else
					talkInfo = replace(out_strWrong,"{$}",rs("rightAnswer")) 
				end if	
			else
				talkInfo = replace(out_strWrong,"{$}",rs("rightAnswer")) 
			end if
			
			'talkInfo = talkInfo & "，" & out_strListenNext
		end if
		
		'更新回答的内容
		call DingDongExamAnswer(rs("id"),obj_inputtext)  

		'读下一题数据
		strsql = "select top 1 * from Question where datatype='train' and Dataid=7 and sort > "&rs("questionSort")&" order by sort asc"
		ors.open strsql,cnn,1,1
		if not ors.eof then
			'读问题			
			talkInfo = talkInfo & "，" & out_strListenNext
			talkInfo = talkInfo & "，" & ors("title")
			rightAnswerNo = ""

			if instr(strQuestionType,trim(ors("questionType"))) > 0 then
				'读答案
				talkInfo = talkInfo & "，" & out_strAnswerList
				strsql = "select  * from Answer where flag=0 and Questionid="&ors("id")
				rrs.open strsql,cnn,1,1
				if not rrs.eof then
					for i=1 to rrs.recordcount 
						talkInfo = talkInfo & "；" & arrAnswerNo(i-1) & "，" & rrs("title")
						if trim(rrs("istrue"))="T" then
							rightAnswerNo = rightAnswerNo & arrAnswerNo(i-1)
						end if
						rrs.movenext
					next
					talkInfo = talkInfo & "，" & replace(out_StrQuestionType,"{$}",ors("questionType"))  
				else
					talkInfo = talkInfo & out_StrError
					endStatus = true
				end if
				rrs.close
			else
				talkInfo = talkInfo & "，" & replace(out_StrQuestionType,"{$}",ors("questionType")) 
			end if
			
			call DingDongExamLog(obj_userid,ors("id"),ors("title"),talkInfo,ors("questionType"),ors("sort"),rightAnswerNo)
		else
			talkInfo = talkInfo & "，" & out_StrComplete
			endStatus = true
		end if
		ors.close		
	else
		talkInfo = out_StrComplete
		endStatus = true
	end if
	rs.close
	
end if


call DingDongAnswer(talkInfo,endStatus)


'应答
sub DingDongAnswer(strContent,strEndStatus)
	Dim strReturn
	strReturn =  "{"
	strReturn =  strReturn & """directive"": {"
	strReturn =  strReturn & """directive_items"": ["
	strReturn =  strReturn & "{"
	strReturn =  strReturn & """content"": """&strContent&""","  
	strReturn =  strReturn & """type"": ""1"""
	strReturn =  strReturn & "}"
	strReturn =  strReturn & "]"
	strReturn =  strReturn & "},"
	'处理听不清begin
	'strReturn =  strReturn & """repeat_directive"": {"
	'strReturn =  strReturn & """directive_items"": ["
	'strReturn =  strReturn & "{"
	'strReturn =  strReturn & """content"": """&out_strUnclear&""","  
	'strReturn =  strReturn & """type"": ""1"""
	'strReturn =  strReturn & "}"
	'strReturn =  strReturn & "]"
	'strReturn =  strReturn & "},"
	'处理听不清end
	strReturn =  strReturn & """extend"":{""NO_REC"":""1""},"
	strReturn =  strReturn & """is_end"":"&strEndStatus&","            ' true | false
	strReturn =  strReturn & """sequence"":"""&obj_sequence&""","      ' 9b1e72c298884ff1aba69f0b14ba9590
	strReturn =  strReturn & """timestamp"":"&ToUnixTime()&","         ' 1526468592000
	strReturn =  strReturn & """versionid"": ""1.0"""
	strReturn =  strReturn & "}"
	response.write strReturn
	
	call DingDongLog("音箱",talkInfo,strReturn)
	
	'response.end
end sub


'=================================公共方法==============================

'语音日志
sub DingDongLog(logType,logInput,logInfo)
	cnn.execute("insert into DingDongLog(logType,logInput,logInfo) values('"&logType&"','"&logInput&"','"&logInfo&"')")
end sub         

'考题日志
sub DingDongExamLog(userID,questionID,questionTitle,questionContent,questionType,questionSort,rightAnswer)
	cnn.execute "insert into DingDongEaxmList (sessionID,questionID,questionTitle,questionContent,questionType,questionSort,rightAnswer) values ('"&userID&"','"&questionID&"','"&questionTitle&"','"&questionContent&"','"&questionType&"','"&questionSort&"','"&rightAnswer&"') "
end sub

'答题
sub DingDongExamAnswer(id,userAnswer)
	cnn.execute "update DingDongEaxmList set answerStatus=1,userAnswer='"&userAnswer&"' where id='"&id&"'"
end sub

'解析input
'function readInput(inputTxt)
'	errInfo = "你说啥，我没听明白！"
''	if isnull(inputTxt) or inputTxt="" then
'		readInput = errInfo
'		exit function
'	end if
'	in_arrKeyWords = split(in_arrKeyWords,",")
	'for m = 0 to ubound(in_arrKeyWords)
	'	in_strKeyWords = in_arrKeyWords(m)
		'in_strKeyWords = split(in_strKeyWords,"|")
		'for n = 0 to ubound(in_strKeyWords)
			'in_KeyWords = in_strKeyWords(n)
			'if inputTxt = in_KeyWords then
				'readInput = in_KeyWords
				'exit function
			'end if
		'next
	'next
'end function
'=================================接收包体==============================

'接受数据
'{
'	"versionid": "1.0",
'	"status": "INTENT",
'	"sequence": "f10ee90bcff644cdab1ed2a18c4ddd63",
'	"timestamp": 1873609207048,
'	"application_info": {
'		"application_id": "ia3a449b",
'		"application_name": "小智"
'	},
'	"session": {
'		"is_new": true,
'		"session_id": "be44d9f4f13a4e789c2d1b5f3d897e84",
'		"attributes": {
'			"focus":"open_xiaozhi",
'			"bizname": "小智",
'			"type": "order"
'		}
'	},
'	"user": {
'		"user_id": "9181c619bbe34e9e935248a70a199e37",
'		"attributes": {}
'	},
'	"input_text": "让小智关闭客厅灯。",
'	"slots": {
'		"focus":"open_xiaozhi",
'		"bizname": "小智",
'		"type": "order"
'	},
'	"extend": {}
'}

%>
<!--#include file="data/Disconnect.asp"-->
<%
response.end
%>