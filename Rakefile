task :default => %w{calcugly.js} do
  sh "jsbeautify calcugly.js > calculator.js"
  sh "rm -f calcugly.js"
end

file "calcugly.js" => %w{calculator.jison} do
  sh "jison calculator.jison calculator.l -o calculator.js; mv calculator.js calcugly.js"
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
