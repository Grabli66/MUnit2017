/****
* Copyright 2016 Massive Interactive. All rights reserved.
* 
* Redistribution and use in source and binary forms, with or without modification, are
* permitted provided that the following conditions are met:
* 
*    1. Redistributions of source code must retain the above copyright notice, this list of
*       conditions and the following disclaimer.
* 
*    2. Redistributions in binary form must reproduce the above copyright notice, this list
*       of conditions and the following disclaimer in the documentation and/or other materials
*       provided with the distribution.
* 
* THIS SOFTWARE IS PROVIDED BY MASSIVE INTERACTIVE ``AS IS'' AND ANY EXPRESS OR IMPLIED
* WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
* FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL MASSIVE INTERACTIVE OR
* CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
* ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
* ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
* 
* The views and conclusions contained in the software and documentation are those of the
* authors and should not be interpreted as representing official policies, either expressed
* or implied, of Massive Interactive.
****/

package massive.munit.client;
import massive.munit.ITestResultClient;
import massive.munit.TestResult;
import massive.munit.util.MathUtil;
import massive.munit.util.Timer;

/**
 * Generates xml formatted tests results compliant for processing by the JUnitReport 
 * Apache Ant task (http://ant.apache.org/manual/Tasks/junitreport.html).
 * 
 * @author Mike Stead
 */
class JUnitReportClient implements IAdvancedTestResultClient {
	
	/**
	 * Default id of this client.
	 */
	public static inline var DEFAULT_ID:String = 'junit';

	/**
	 * The unique identifier for the client.
	 */
	public var id(default, null):String;
	
	/**
	 * Handler which if present, is called when the client has completed generating its results.
	 */
	@:isVar public var completionHandler(get, set):ITestResultClient->Void;
	
	function get_completionHandler():ITestResultClient->Void {
		return completionHandler;
	}
	function set_completionHandler(value:ITestResultClient->Void):ITestResultClient->Void {
		return completionHandler = value;
	}

	/**
	 * Newline delimiter. Defaults to '\n'.
	 * 
	 * <p>
	 * Should be set before the client is passed to a test runner.
	 * </p>
	 */
	public var newline:String;
	var xml:StringBuf;
	var testSuiteXML:StringBuf;
	var currentTestClass:String;
	var suitePassCount:Int;
	var suiteFailCount:Int;
	var suiteErrorCount:Int;
	var suiteExecutionTime:Float;

	/**
	 * Class constructor.
	 */
	public function new() {
		id = DEFAULT_ID;
		currentTestClass = "";		
		newline = "\n";
		testSuiteXML = null;
		xml = new StringBuf();
		xml.add("<testsuites>"); xml.add(newline);
	}
	
	/**
	 * Classed when test class changes
	 *
	 * @param className		qualified name of current test class
	 */
	public function setCurrentTestClass(className:String) {
		if(currentTestClass == className) return;
		if(currentTestClass != null) endTestSuite();
		currentTestClass = className;
		if(currentTestClass != null) startTestSuite();
	}

	/**
	 * Called when a test passes.
	 *  
	 * @param	result			a passed test result
	 */
	public function addPass(result:TestResult) {
		suitePassCount++;
		testSuiteXML.add('<testcase classname="');
		testSuiteXML.add(result.className);
		testSuiteXML.add('" name="');
		testSuiteXML.add(result.name);
		testSuiteXML.add('" time="');
		testSuiteXML.add(MathUtil.round(result.executionTime, 5));
		testSuiteXML.add('" />');
		testSuiteXML.add(newline);
	}
	
	/**
	 * Called when a test fails.
	 *  
	 * @param	result			a failed test result
	 */
	public function addFail(result:TestResult) {
		suiteFailCount++;
		testSuiteXML.add('<testcase classname="');
		testSuiteXML.add(result.className);
		testSuiteXML.add('" name="');
		testSuiteXML.add(result.name);
		testSuiteXML.add('" time="');
		testSuiteXML.add(MathUtil.round(result.executionTime, 5));
		testSuiteXML.add('" >');
		testSuiteXML.add(newline);
		testSuiteXML.add('<failure message="');
		testSuiteXML.add(result.failure.message);
		testSuiteXML.add('" type="');
		testSuiteXML.add(result.failure.type);
		testSuiteXML.add('">');
		testSuiteXML.add(result.failure);
		testSuiteXML.add('</failure>');
		testSuiteXML.add(newline);
		testSuiteXML.add('</testcase>');
		testSuiteXML.add(newline);
	}
	
	/**
	 * Called when a test triggers an unexpected exception.
	 *  
	 * @param	result			an erroneous test result
	 */
	public function addError(result:TestResult) {
		suiteErrorCount++;
		testSuiteXML.add('<testcase classname="');
		testSuiteXML.add(result.className);
		testSuiteXML.add('" name="');
		testSuiteXML.add(result.name);
		testSuiteXML.add('" time="');
		testSuiteXML.add(MathUtil.round(result.executionTime, 5));
		testSuiteXML.add('" >');
		testSuiteXML.add(newline);
		testSuiteXML.add('<error message="');
		testSuiteXML.add(result.error.message);
		testSuiteXML.add('" type="');
		testSuiteXML.add(result.error.type);
		testSuiteXML.add('">');
		testSuiteXML.add(result.error);
		testSuiteXML.add('</error>');
		testSuiteXML.add(newline);
		testSuiteXML.add('</testcase>');
		testSuiteXML.add(newline);
	}
	
	/**
	 * Called when a test has been ignored.
	 *
	 * @param	result			an ignored test
	 */
	public function addIgnore(result:TestResult) {
		// TODO: Looks like the "skipped" element is not in the official junit report schema
		//       so ignoring the reporting of this for now. 
		//       https://issues.apache.org/bugzilla/show_bug.cgi?id=43969
		//
		//       ms 4.9.2011
	}

	/**
	 * Called when all tests are complete.
	 *  
	 * @param	testCount		total number of tests run
	 * @param	passCount		total number of tests which passed
	 * @param	failCount		total number of tests which failed
	 * @param	errorCount		total number of tests which were erroneous
	 * @param	ignoreCount		total number of ignored tests
	 * @param	time			number of milliseconds taken for all tests to be executed
	 * @return	collated test result data
	 */
	public function reportFinalStatistics(testCount:Int, passCount:Int, failCount:Int, errorCount:Int, ignoreCount:Int, time:Float):Dynamic {
		xml.add("</testsuites>");
		if (completionHandler != null) completionHandler(this);
		return xml.toString();
	}
	
	function startTestSuite() {
		suitePassCount = 0;
		suiteFailCount = 0;
		suiteErrorCount = 0;
		suiteExecutionTime = Timer.stamp();
		testSuiteXML = new StringBuf();
	}
	
	function endTestSuite() {
		if (testSuiteXML == null) return;
		var suiteTestCount:Int = suitePassCount + suiteFailCount + suiteErrorCount;
		suiteExecutionTime = Timer.stamp() - suiteExecutionTime;
		xml.add('<testsuite errors="');
		xml.add(suiteErrorCount);
		xml.add('" failures="');
		xml.add(suiteFailCount);
		xml.add('" hostname="" name="');
		xml.add(currentTestClass);
		xml.add('" tests="');
		xml.add(suiteTestCount);
		xml.add('" time="');
		xml.add(MathUtil.round(suiteExecutionTime, 5));
		xml.add('" timestamp="');
		xml.add(Date.now());
		xml.add('">');
		xml.add(newline);
		testSuiteXML.add('<system-out></system-out>'); testSuiteXML.add(newline);
		testSuiteXML.add('<system-err></system-err>'); testSuiteXML.add(newline);
		xml.add(testSuiteXML.toString());
		xml.add('</testsuite>');
		xml.add(newline);
	}
}
