# DINGDONG
叮咚核心

```
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Data;

namespace UI.Datacenter
{
    /// <summary>
    /// DDAPI 的摘要说明
    /// </summary>
    public class DDAPI : IHttpHandler
    {
        string reg1;
        Match m1;
        BLL.ZYWBLL MyZYWBLL = new BLL.ZYWBLL();
        MODEL.DingDongEaxmList MyDingDongEaxmList = null;
        MODEL.Question MyQuestion = null;
        List<MODEL.Answer> MyAnswer = null;
        MODEL.Useranswer MyUseranswer = null;
        MODEL.UserAnswerRecord MyUserAnswerRecord = null;
        Function MyFunction = new Function();
        BLL.HMXBLL MyHMXBLL = new BLL.HMXBLL();
        BLL.XCLBLL MyXCLBLL = new BLL.XCLBLL();
        public string talkInfo = "";
        //语音关键词----用户
        string in_StrBegin = "打开永修技术|打开小新考试";
        string in_StrExit = "退出考试|退出|结束|关闭|再见|拜拜";

        string in_StrNext = "不知道|不清楚|下一题|下一个|下一道";
        string in_StrRepeat = "没听清|听不清|再说一遍|再来一遍|再来一次|再说一次|请重复";

        //语音关键词----音箱
        string out_strBegin = "开始考试，请听题";
        string out_strExit = "退出考试，会话结束";
        string out_strRight = "回答正确";
        string out_strWrong = "回答错误，正确答案是：{$}";
        string out_strAnswerList = "可选答案";
        string out_strQuestionType = "本题为{$}题，请说出您的答案";
        //string out_strListen = "请听题";
        string out_strListenAgin = "请重新听题";
        string out_strListenNext = "请听下一题";
        string out_StrComplete = "答题已经完毕，会话结束";
        //string out_strUnclear = "你说啥，我没听明白";
        string out_StrError = "出错了，考题准备失败";

        //问题类型
        string strQuestionType = "多选|单选";
        //答案数组
        string[] arrAnswerNo = new string[] { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" };
        string[] arrAnswerStr = new string[] { "A", "哎", "嗨", "AB", "ABB", "BABY", "AC", "ABC", "ACB", "B", "BA", "BC", "BAC", "BCA", "C", "CA", "CB", "CAB", "CBA", "ABCD" };
        //string arrAnswerNo = "";
        //string arrAnswerStr = "";
        string rightAnswerNo = "";

        string endStatus = "false";
        string obj_sequence;
        string obj_inputtext;
        string obj_userid;
        string session_id;
        //string obj_keywords;
        string[] sArray0;
        string dataid;
        MODEL.Train MyTrain = null;
        int extend = 0;
        string[] sArray4 = null;
        string Totalscroe = "";

        string dduserid = "";
        string reldeferentid = "";

        public void ProcessRequest(HttpContext context)
        {
            #region 接收通过POST的提交方式发送过来的JSON格式数据包
            Stream s = context.Request.InputStream;
            byte[] b = new byte[s.Length];
            s.Read(b, 0, (int)s.Length);
            string PostStr = Encoding.UTF8.GetString(b);
            #endregion

            #region 通过关键字获取user_id、input_text、sequence
            string user_id = "";
            string input_text = "";
            string sequence = "";
            reg1 = "\"user_id\":([\\s\\S]*?)\"([\\s\\S]*?)\"";
            m1 = Regex.Match(PostStr, reg1, RegexOptions.IgnoreCase);
            if (m1.Success)
            {
                user_id = m1.Groups[2].Value.ToString();
            }
            reg1 = "\"input_text\":([\\s\\S]*?)\"([\\s\\S]*?)\"";
            m1 = Regex.Match(PostStr, reg1, RegexOptions.IgnoreCase);
            if (m1.Success)
            {
                input_text = m1.Groups[2].Value.ToString();
            }
            reg1 = "\"sequence\":([\\s\\S]*?)\"([\\s\\S]*?)\"";
            m1 = Regex.Match(PostStr, reg1, RegexOptions.IgnoreCase);
            if (m1.Success)
            {
                sequence = m1.Groups[2].Value.ToString();
            }
            reg1 = "\"session_id\":([\\s\\S]*?)\"([\\s\\S]*?)\"";
            m1 = Regex.Match(PostStr, reg1, RegexOptions.IgnoreCase);
            if (m1.Success)
            {
                session_id = m1.Groups[2].Value.ToString();
            }

            obj_sequence = sequence.Replace("\n", "").Replace(" ", "").Replace(",", "").Replace("\t", "").Replace("\r", "");//id 对话ID 一进一出(只有一对)obj.sequence
            obj_inputtext = input_text.Replace("\n", "").Replace(" ", "").Replace(",", "").Replace("\t", "").Replace("\r", "");//我对音像说的内容obj.input_text
            obj_userid = user_id.Replace("\n", "").Replace(" ", "").Replace(",", "").Replace("\t", "").Replace("\r", "");//音像的应用IDobj.user.user_idobj.user.
            session_id = session_id.Replace("\n", "").Replace(" ", "").Replace(",", "").Replace("\t", "").Replace("\r", "");//sessionid
            sArray0 = in_StrBegin.Split(new char[] { '|' });//开始
            string[] sArray = in_StrExit.Split(new char[] { '|' });//退出
            string[] sArray2 = in_StrRepeat.Split(new char[] { '|' });//重复
            string[] sArray3 = in_StrNext.Split(new char[] { '|' });//下一题
            sArray4 = strQuestionType.Split(new char[] { '|' });//问题类型       

            MyTrain = MyHMXBLL.GetTraintop();//获取Train表的id
            MyUseranswer = new MODEL.Useranswer();
            MyUseranswer.Createtime = DateTime.Now.ToString();
            MyUseranswer.Dataid = MyTrain.Id;
            MyUseranswer.Datatype = "Train";
            MyUseranswer.Flag = "0";
            //MyUseranswer.Userid = "1";

            MyUserAnswerRecord = new MODEL.UserAnswerRecord();
            MyUserAnswerRecord.dataid = MyTrain.Id;
            MyUserAnswerRecord.datatype = "Train";
            MyUserAnswerRecord.createtime = DateTime.Now.ToString();
            MyUserAnswerRecord.flag = "0";
            MyUserAnswerRecord.shopid = "7";
            //MyUserAnswerRecord.userid = "1";

            MyQuestion = new MODEL.Question();
            MyQuestion = MyZYWBLL.GetQuestionby("Train", MyTrain.Id);

            //MyZYWBLL.DingDongLog("用户", obj_inputtext, PostStr, MyTrain.Id);//存入请求包
            //string strAction = "";

            bool isdakai = false;
            foreach (string item in sArray0)
            {
                if (obj_inputtext.Contains(item))
                {
                    isdakai = true;
                    break;
                }
            }
            bool istuichu = false;
            foreach (string item in sArray)
            {
                if (obj_inputtext.Contains(item))
                {
                    istuichu = true;
                    break;
                }
            }
            bool isagain = false;
            foreach (string item in sArray2)
            {
                if (obj_inputtext.Contains(item))
                {
                    isagain = true;
                    break;
                }
            }
            bool isnext = false;
            foreach (string item in sArray3)
            {
                if (obj_inputtext.Contains(item))
                {
                    isnext = true;
                    break;
                }
            }

            if (isdakai)
            {
                //清空历史记录
                MyZYWBLL.UPDingDongEaxmList(obj_userid);
                string deferentid = MyZYWBLL.insertandselect(obj_userid, DateTime.Now, MyTrain.Id, "Train");//获取id
                MyZYWBLL.tempdeferentinset(session_id, deferentid);
                //

                //开始考试，播第一题
                talkInfo = out_strBegin;
                if (MyQuestion != null)
                {
                    //读问题
                    talkInfo = talkInfo + "，" + MyQuestion.Title;
                    if (sArray4.ToList().IndexOf(MyQuestion.Questiontype.Trim()) >= 0)
                    {
                        //读答案
                        string out_strAnswerType = "";
                        talkInfo = talkInfo + "，" + out_strAnswerType;
                        MyAnswer = new List<MODEL.Answer>();
                        MyAnswer = MyZYWBLL.GetAnswerByid(MyQuestion.Id);
                        if (MyAnswer != null)
                        {

                            for (int i = 0; i <= MyAnswer.Count - 1; i++)
                            {
                                talkInfo = talkInfo + "；" + arrAnswerNo[i] + "，" + MyAnswer[i].Title;
                                if (MyAnswer[i].Istrue.Trim() == "T")
                                {
                                    rightAnswerNo = rightAnswerNo + arrAnswerNo[i];
                                }
                            }
                            talkInfo = talkInfo + "，" + out_strQuestionType.Replace("{$}", MyQuestion.Questiontype);
                        }
                        else
                        {
                            talkInfo = out_StrError;
                            endStatus = "true";
                        }
                    }
                    else
                    {
                        talkInfo = talkInfo + "，" + out_strQuestionType.Replace("{$}", MyQuestion.Questiontype);

                    }
                    MyZYWBLL.DingDongExamLog(obj_userid, MyQuestion.Id, MyQuestion.Title, talkInfo, MyQuestion.Questiontype, MyQuestion.Sort.ToString(), rightAnswerNo, MyTrain.Id);
                }
                else
                {

                    talkInfo = out_StrError;
                    endStatus = "true";
                }
            }

            //结束
            //更新所有题的状态
            if (istuichu)
            {
                talkInfo = out_strExit;
                endStatus = "true";
                dduserid = MyZYWBLL.selecttempT(session_id);
                int g = MyZYWBLL.UpdateDingDongDifferent(MyTrain.Id, "0", dduserid); //修改DingDongDifferent的stasus状态
                int i = MyZYWBLL.deletetempT(session_id);//清除临时表
                MyZYWBLL.deletetempdeferent(session_id);//清除临时表
                MyZYWBLL.UPDATEzhunagtai(obj_userid);
            }

            if (isagain)
            {
                MyDingDongEaxmList = new MODEL.DingDongEaxmList();
                MyDingDongEaxmList = MyZYWBLL.GetDingDongEaxmListTop(obj_userid);
                //'读问题
                if (MyDingDongEaxmList != null)
                {
                    talkInfo = out_strListenAgin;
                    talkInfo = talkInfo + "，" + MyDingDongEaxmList.questionTitle;
                    rightAnswerNo = "";
                    //读答案
                    if (sArray4.ToList().IndexOf(MyDingDongEaxmList.questionType.Trim()) >= 0)
                    {
                        talkInfo = talkInfo + "，" + out_strAnswerList;
                        MyAnswer = new List<MODEL.Answer>();
                        MyAnswer = MyZYWBLL.GetAnswerByid(MyDingDongEaxmList.questionID);
                        if (MyAnswer != null)
                        {
                            for (int i = 0; i <= MyAnswer.Count - 1; i++)
                            {
                                talkInfo = talkInfo + "；" + arrAnswerNo[i] + "，" + MyAnswer[i].Title;
                                if (MyAnswer[i].Istrue.Trim() == "T")
                                {
                                    rightAnswerNo = rightAnswerNo + arrAnswerNo[i];
                                }

                            }
                            talkInfo = talkInfo + "，" + out_strQuestionType.Replace("{$}", MyDingDongEaxmList.questionType);
                        }
                        else
                        {
                            talkInfo = talkInfo + out_StrError;
                            endStatus = "true";
                        }

                    }
                    else
                    {
                        talkInfo = talkInfo + "，" + out_strQuestionType.Replace("{$}", MyDingDongEaxmList.questionType);
                    }
                }
                else
                {
                    talkInfo = out_StrComplete;
                    endStatus = "true";
                }
            }

            if (!isdakai && !isagain && !istuichu)
            {
                MyDingDongEaxmList = new MODEL.DingDongEaxmList();
                MyDingDongEaxmList = MyZYWBLL.GetDingDongEaxmListTop(obj_userid);

                MyUseranswer.Questionid = MyDingDongEaxmList.questionID;
                MyUseranswer.Questiontype = MyDingDongEaxmList.questionType;

                MODEL.Question Q = new MODEL.Question();
                Q = MyZYWBLL.GetQuestionscroe(MyDingDongEaxmList.questionID, MyTrain.Id);//获取题目分数

                dduserid = MyZYWBLL.selecttempT(session_id);

                if (MyDingDongEaxmList != null)
                {

                    string rightAnswer = MyDingDongEaxmList.rightAnswer.ToUpper();
                    if (isnext)
                    {
                        MyUseranswer.IsTrue = "F";
                        MyUseranswer.Score = 0;
                        MyUseranswer.Answerid = "";
                        MyUseranswer.AnswerContent = "下一题";

                        MyUserAnswerRecord.userid = dduserid;
                        MyUseranswer.Userid = dduserid;
                        int u = MyZYWBLL.AddUserAnswerRecorDD(MyUserAnswerRecord);//向UserAnswerRecord插入数据并返回id
                        MyUseranswer.AnswerRecordID = u.ToString();
                        MyZYWBLL.AddUseranswer(MyUseranswer);//向useranswer表插入数据
                        next();
                    }
                    else
                    {
                        string userAnswer = obj_inputtext.ToUpper();
                        string includeAnswer = "";
                        for (int i = 0; i <= arrAnswerStr.Length - 1; i++)
                        {
                            if (userAnswer == arrAnswerStr[i])
                            {
                                includeAnswer = arrAnswerStr[i];
                            }
                        }
                        includeAnswer = includeAnswer.ToUpper();
                        DataSet ds = MyHMXBLL.GetAnswerByQuestionidDD(MyDingDongEaxmList.questionID);
                        string x = "";
                        for (int i = 0; i < ds.Tables[0].Rows.Count; i++)
                        {
                            if (i == 0)
                            {
                                x = ds.Tables[0].Rows[i][0].ToString();
                            }
                            else
                            {
                                x = x + "," + ds.Tables[0].Rows[i][0].ToString();
                            }

                        }
                        if (includeAnswer != "")//判断对错
                        {
                            if (includeAnswer == "ABB" && rightAnswer == "AB")
                            {
                                includeAnswer = "AB";
                                talkInfo = out_strRight;
                                MyUseranswer.IsTrue = "T";
                                MyUseranswer.Score = Q.Score;
                                MyUseranswer.Answerid = x;
                                MyUseranswer.AnswerContent = includeAnswer;
                            }
                            else if (includeAnswer == "BABY" && rightAnswer == "AB")
                            {
                                includeAnswer = "AB";
                                talkInfo = out_strRight;
                                MyUseranswer.IsTrue = "T";
                                MyUseranswer.Score = Q.Score;
                                MyUseranswer.Answerid = x;
                                MyUseranswer.AnswerContent = includeAnswer;
                            }
                            else if ((includeAnswer == "哎" || includeAnswer == "嗨") && rightAnswer == "A")
                            {
                                includeAnswer = "A";
                                talkInfo = out_strRight;
                                MyUseranswer.IsTrue = "T";
                                MyUseranswer.Score = Q.Score;
                                MyUseranswer.Answerid = x;
                                MyUseranswer.AnswerContent = includeAnswer;
                            }
                            else if (includeAnswer == rightAnswer)
                            {
                                talkInfo = out_strRight;
                                MyUseranswer.IsTrue = "T";
                                MyUseranswer.Score = Q.Score;
                                MyUseranswer.Answerid = x;
                                MyUseranswer.AnswerContent = includeAnswer;
                            }
                            else
                            {
                                talkInfo = out_strWrong.Replace("{$}", MyDingDongEaxmList.rightAnswer);
                                //answerids = GetMyAnswerID(includeAnswer);
                                MyUseranswer.IsTrue = "F";
                                MyUseranswer.Score = 0;
                                MyUseranswer.Answerid = "";
                                MyUseranswer.AnswerContent = includeAnswer;
                            }

                            MyUserAnswerRecord.userid = dduserid;
                            MyUseranswer.Userid = dduserid;
                            int u = MyZYWBLL.AddUserAnswerRecorDD(MyUserAnswerRecord);//向UserAnswerRecord插入数据并返回id
                            MyUseranswer.AnswerRecordID = u.ToString();
                            MyZYWBLL.AddUseranswer(MyUseranswer);//向useranswer表插入数据
                            Totalscroe = MyZYWBLL.TotalScores(MyTrain.Id, dduserid);//获取得分
                            next();
                        }
                        else if (MyDingDongEaxmList.questionType.Trim() == "开放")
                        {
                            if (MyDingDongEaxmList.questionSort == "1")//xingm
                            {

                                int i = MyZYWBLL.tempTinset(session_id, userAnswer);
                                bool isnum = false;
                                int x1;
                                if (int.TryParse(userAnswer, out x1))
                                {
                                    isnum = true;
                                }
                                else
                                {
                                    isnum = false;
                                }
                                if (isnum&&MyXCLBLL.GetShopuserBySql(userAnswer) != null)
                                {
                                    MyUseranswer.IsTrue = "F";
                                    MyUseranswer.Score = Q.Score;
                                    MyUseranswer.Answerid = "";
                                    MyUseranswer.AnswerContent = userAnswer;
                                    MyUserAnswerRecord.userid = userAnswer;
                                    MyUseranswer.Userid = userAnswer;

                                    int u = MyZYWBLL.AddUserAnswerRecorDD(MyUserAnswerRecord);//向UserAnswerRecord插入数据并返回id
                                    MyUseranswer.AnswerRecordID = u.ToString();
                                    MyZYWBLL.AddUseranswer(MyUseranswer);//向useranswer表插入数据
                                    next();
                                }
                                else
                                {
                                    talkInfo = "您的工号不存在，会话话已结束！";
                                    endStatus = "true";
                                    dduserid = MyZYWBLL.selecttempT(session_id);
                                    int g = MyZYWBLL.UpdateDingDongDifferent(MyTrain.Id, "0", dduserid); //修改DingDongDifferent的stasus状态
                                    int v = MyZYWBLL.deletetempT(session_id);//清除临时表
                                    MyZYWBLL.deletetempdeferent(session_id);//清除临时表
                                    MyZYWBLL.UPDATEzhunagtai(obj_userid);
                                }
                                //MyUseranswer.IsTrue = "T";
                                //MyUseranswer.Score = Q.Score;
                                //MyUseranswer.Answerid = "";
                                //MyUseranswer.AnswerContent = userAnswer;
                                //MyUserAnswerRecord.userid = userAnswer;
                                //MyUseranswer.Userid = userAnswer;

                                //int u = MyZYWBLL.AddUserAnswerRecorDD(MyUserAnswerRecord);//向UserAnswerRecord插入数据并返回id
                                //MyUseranswer.AnswerRecordID = u.ToString();
                                //MyZYWBLL.AddUseranswer(MyUseranswer);//向useranswer表插入数据
                                //next();
                            }
                        }
                        else
                        {
                            extend = 1;
                            talkInfo = "请您按照规范答题，重新听题";
                        }

                    }

                }
                else
                {
                    talkInfo = out_StrComplete;
                    string scroe = MyZYWBLL.GetScore(Totalscroe);
                    dduserid = MyZYWBLL.selecttempT(session_id);
                    int m = MyZYWBLL.UpdateDingDongDifferent(MyTrain.Id, scroe, dduserid);//修改DingDongDifferent的stasus状态
                    int i = MyZYWBLL.deletetempT(session_id);//清除临时表
                    MyZYWBLL.deletetempdeferent(session_id);//清除临时表
                    endStatus = "true";
                }
            }

            reldeferentid = MyZYWBLL.selecttempdeferentid(session_id);
            MyZYWBLL.DingDongLog("用户", obj_inputtext, PostStr, reldeferentid);//存入请求包
            string str = DingDongAnswer(talkInfo, endStatus, obj_inputtext, isdakai, extend);
            context.Response.Write(str);
            #endregion

        }

        //下一题
        public void next()
        {
            //更新回答的内容
            MyZYWBLL.DingDongExamAnswer(MyDingDongEaxmList.id, obj_inputtext);
            //读下一题数据
            MyQuestion = new MODEL.Question();
            MyQuestion = MyZYWBLL.GetQuestionByquestionSort(MyDingDongEaxmList.questionSort, MyTrain.Id);
            //读问题
            if (MyQuestion != null)
            {
                talkInfo = talkInfo + "，" + out_strListenNext;
                talkInfo = talkInfo + "，" + MyQuestion.Title;
                rightAnswerNo = "";

                //读答案
                if (sArray4.ToList().IndexOf(MyQuestion.Questiontype.Trim()) >= 0)
                {
                    talkInfo = talkInfo + "，" + out_strAnswerList;
                    MyAnswer = new List<MODEL.Answer>();
                    MyAnswer = MyZYWBLL.GetAnswerByid(MyQuestion.Id);
                    if (MyAnswer != null)
                    {
                        for (int i = 0; i <= MyAnswer.Count - 1; i++)
                        {
                            talkInfo = talkInfo + "；" + arrAnswerNo[i] + "，" + MyAnswer[i].Title;
                            if (MyAnswer[i].Istrue.Trim() == "T")
                            {
                                rightAnswerNo = rightAnswerNo + arrAnswerNo[i];
                            }
                        }
                        talkInfo = talkInfo + "，" + out_strQuestionType.Replace("{$}", MyQuestion.Questiontype);

                    }
                    else
                    {
                        talkInfo = talkInfo + out_StrError;
                        endStatus = "true";
                    }

                }
                else
                {
                    talkInfo = talkInfo + "，" + out_strQuestionType.Replace("{$}", MyQuestion.Questiontype);
                }

                MyZYWBLL.DingDongExamLog(obj_userid, MyQuestion.Id, MyQuestion.Title, talkInfo, MyQuestion.Questiontype, MyQuestion.Sort.ToString(), rightAnswerNo, MyTrain.Id);
            }
            else
            {
                talkInfo = talkInfo + "，" + out_StrComplete;

                string scroe = MyZYWBLL.GetScore(Totalscroe);
                dduserid = MyZYWBLL.selecttempT(session_id);
                int z = MyZYWBLL.UpdateDingDongDifferent(MyTrain.Id, scroe, dduserid);//修改DingDongDifferent的stasus状态
                int i = MyZYWBLL.deletetempT(session_id);//清除临时表
                //MyZYWBLL.deletetempdeferent(session_id);//清除临时表
                //reldeferentid = reldeferentid;
                //MyZYWBLL.AddUseranswer(MyUseranswer);//向useranswer表插入数据
                endStatus = "true";
            }
        }

        public bool IsReusable
        {
            get { return true; }
        }
        //应答
        public string DingDongAnswer(string strContent, string strEndStatus, string obj_inputtext, bool isbaohan, int extend)
        {
            string strReturn = "";
            long ToUnixTime = (DateTime.Now.ToUniversalTime().Ticks - 621355968000000000) / 10000;
            strReturn = "{";
            strReturn = strReturn + "\"directive\": {";
            strReturn = strReturn + "\"directive_items\": [";
            strReturn = strReturn + "{";
            strReturn = strReturn + "\"content\": \"" + strContent + "\",";
            strReturn = strReturn + "\"type\": 1";
            strReturn = strReturn + "}";
            strReturn = strReturn + "]";
            strReturn = strReturn + "},";
            //if (isbaohan)
            //{
            //    strReturn = strReturn + "\"extend\":{\"NO_REC\":0},";
            //}
            //else
            //{
            //    strReturn = strReturn + "\"extend\":{\"NO_REC\":1},";
            //}
            strReturn = strReturn + "\"extend\":{\"NO_REC\":" + extend + "},";
            strReturn = strReturn + "\"is_end\":\"" + strEndStatus + "\",";           // ' true | false
            strReturn = strReturn + "\"sequence\":\"" + obj_sequence + "\",";     // ' 9b1e72c298884ff1aba69f0b14ba9590
            strReturn = strReturn + "\"timestamp\":\"" + ToUnixTime + "\",";       // ' 1526468592000
            strReturn = strReturn + "\"versionid\": \"1.0\"";
            strReturn = strReturn + "}";
            MyZYWBLL.DingDongLog("音箱", talkInfo, strReturn, reldeferentid);
            return strReturn;
        }

        public string GetMyAnswerID(string xuanze)
        {
            string all = "ABCDEFG";
            string shuzi = "";
            xuanze.ToUpper();
            for (int i = 0; i < xuanze.Length - 1; i++)
            {
                string str2 = xuanze.Substring(i, 1);
                int x = all.IndexOf(str2);
                if (shuzi == "")
                {
                    shuzi = MyAnswer[x].Id;
                }
                else
                {
                    shuzi = shuzi + "," + MyAnswer[x].Id;
                }
            }
            return shuzi;
        }

    }
}
```
