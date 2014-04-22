task :default => %w{calculator.js} 

file "calculator.js" => %w{calculator.jison} do
  sh "jison calculator.jison calculator.l -o calculator.js"
end

task :testf do
  sh " open -a firefox test/test.html"
end

task :tests do
  sh " open -a safari test/test.html"
end

task :clean do
  sh "rm -f calculator.err  calculator.output calculator.tab.jison  calculator.js calculator.bak"
end

desc "print files"
task :print do
  sh "a2ps --columns=1 -f 8 -R calculator.jison -o out.ps"
end
