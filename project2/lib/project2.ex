defmodule TopologyStarter do

  def gossipFull(noNodes) do
    for i <- 1..noNodes do
      spawn(fn -> Gossip_Full.start_link(i,noNodes-1,1) end)  # spawns new process for each of the nodes
    end
    converger(noNodes,"gossip") # starts convergence of the nodes created
  end

  def gossip3D(noNodes) do
    indices = round(:math.pow(noNodes,(1/3))) # finds the cube root of the nodes given to get indexes
    k=0
    for i <- 1..noNodes do
      k=:math.floor(i/(indices*indices))
      neighboursIndices =
        cond do
          i == 1 -> [i+1,i+indices,i+indices*indices]
          i == indices -> [i-1,i+indices,i+indices*indices]
          i == indices*indices - indices + 1 -> [i+1,i-indices,i+indices*indices]
          i == indices*indices -> [i-1,i-indices,i+indices*indices]
          i < indices -> [i-1,i+1,i+indices,i+indices*indices]
          i > indices*indices - indices + 1 and i < indices*indices -> [i-1,i+1,i-indices,i+indices*indices]

          i == indices*indices*(indices-1) + 1 -> [i+1,i+indices,i-indices*indices]
          i == indices*indices*(indices-1) + indices -> [i-1,i+indices,i-indices*indices]
          i == indices*indices*indices - indices + 1 -> [i+1,i-indices,i-indices*indices]
          i == indices*indices*indices -> [i-1,i-indices,i-indices*indices]
          i < indices*indices*(indices-1) + indices and i > indices*indices*(indices-1) + 1 -> [i-1,i+1,i+indices,i-indices*indices]
          i > indices*indices*indices - indices + 1 and i < indices*indices*indices -> [i-1,i+1,i-indices,i-indices*indices]

          i == k*indices*indices + 1 -> [i+1,i+indices,i+indices*indices,i-indices*indices]
          i == k*indices*indices + indices -> [i-1,i+indices,i+indices*indices,i-indices*indices]
          i == k*indices*indices + indices*indices - indices + 1 -> [i+1,i-indices,i+indices*indices,i-indices*indices]
          i == k*indices*indices + indices*indices -> [i-1,i-indices,i+indices*indices,i-indices*indices]

          i < k*indices*indices + indices and   i > k*indices*indices + 1 -> [i-1,i+1,i+indices,i+indices*indices,i-indices*indices]
          i > k*indices*indices + indices*indices - indices + 1 and i < k*indices*indices -> [i-1,i+1,i-indices,i+indices*indices,i-indices*indices]

          rem(i-1,indices) == 0 and k==0 ->
          [i+1,i-indices,i+indices,i+indices*indices]

          rem(i-1,indices) == 0 and k== indices-1 ->
          [i+1,i-indices,i+indices,i-indices*indices]

          rem(i-1,indices) == 0 ->
          [i+1,i-indices,i+indices ,i+indices*indices,i-indices*indices]

          rem(i,indices) == 0 and k==0 ->
          [i-1,i-indices,i+indices,i+indices*indices]

          rem(i,indices) == 0 and k== indices-1 ->
          [i-1,i-indices,i+indices,i-indices*indices]

          rem(i,indices) == 0 ->
          [i-1,i-indices,i+indices,i+indices*indices,i-indices*indices]

          k==0 ->
          [i-1,i+1,i+indices,i-indices,i+indices*indices]

          k==indices-1 ->
          [i-1,i+1,i+indices,i-indices,i-indices*indices]

          true -> [i-1,i+1,i-indices,i+indices,i+indices*indices,i-indices*indices]
        end
        pid = spawn(fn -> Gossip_2D_3D_Torus.start_link(i,neighboursIndices,noNodes,1) end) # spawns new process, with neighbours known for all the nodes
    end
    converger(noNodes,"gossip")  # starts convergence of the nodes created
  end

  def gossipRandom2D(noNodes) do # here consider as neighbour nodes if the distance between either x or y coordinates is 0.1
    listx = 1..noNodes |> Enum.map(fn _ -> Enum.random(1..100000)/100000 end) # get list of x-coordinates for each of the nodes
    listy =1..noNodes |> Enum.map(fn _ -> Enum.random(1..100000)/100000 end)  # get list of y-coordinates for each of the nodes
    for i <- 0..noNodes-1 do
      listm=Enum.with_index(listx)
      listn=Enum.with_index(listy)
      list_x =  Enum.filter_map(listm , fn({x,_}) -> abs(Enum.at(listx,i)-x)<= 0.1 end, fn {_,x} -> "#{x+1}" end)
      finalx = Enum.map(list_x,fn(x) -> String.to_integer(x,10) end)
      list_y =  Enum.filter_map(listn , fn({x,_}) -> abs(Enum.at(listy,i)-x)<= 0.1 end, fn {_,x} -> "#{x+1}" end)
      finaly = Enum.map(list_y,fn(x) -> String.to_integer(x,10) end)
      neighboursIndices = finalx ++ finaly
      pid = spawn(fn -> Gossip_2D_3D_Torus.start_link(i,neighboursIndices,noNodes,1) end)
    end
    IO.puts "Waiting for convergence"
    final_convergence = Task.async(fn -> converging(noNodes,0) end) # get the node for the which the final convergence os occuring
    :global.register_name(:msgproc,final_convergence.pid) # register the pid of the final convergence process
    :global.register_name(:unconverged,self())  # register the unconverged processes
    st_time = :os.system_time(:millisecond) #get the system time before starting gossip
    start_gossip(noNodes,0) #calls the function to begin passing the message to all the nodes
    Task.await(final_convergence, :infinity) #waits for the final convergence process to give back reply
    IO.puts ""
    IO.puts ""
    IO.puts "Time utilized to converge: #{inspect :os.system_time(:millisecond)-st_time} milliseconds"
  end

  def gossipTorus(noNodes) do
    indices = round(:math.sqrt(noNodes))
    for i <- 1..noNodes do
      neighboursIndices =
        cond do
          i == 1 -> [i+1,i+indices,indices,noNodes-indices+1]
          i == indices -> [i-1,i+indices,1,noNodes]
          i == noNodes - indices + 1 -> [i+1,i-indices,1,noNodes]
          i == noNodes -> [i-1,i-indices,noNodes-indices+1,indices]
          i < indices -> [i-1,i+1,i+indices,i+noNodes-indices]
          i > noNodes - indices + 1 and i < noNodes -> [i-1,i+1,i-indices,i-noNodes+indices]
          rem((i-1),indices) == 0 -> [i+1,i-indices,i+indices,i-1+indices]
          rem(i,indices) == 0 -> [i-1,i-indices,i+indices,i+1-indices]
          true -> [i-1,i+1,i-indices,i+indices]
        end
        pid = spawn(fn -> Gossip_2D_3D_Torus.start_link(i,neighboursIndices,noNodes,1) end)
    end
    converger(noNodes,"gossip")
  end

  def gossipLine(noNodes) do
    for i <- 1..noNodes do
      neighboursIndices =
        cond do
          i == 1 -> [i+1]
          i == noNodes -> [i-1]
          true -> [i-1,i+1]
        end
      spawn(fn -> Gossip_Line.start_link(i,neighboursIndices,1) end)
    end
    converger(noNodes,"gossip")
  end

  def gossipImpLine(noNodes) do
    for i <- 1..noNodes do
        neighboursIndices =
          cond do
            i == 1 -> [i+1, :rand.uniform(noNodes)]
            i == noNodes -> [i-1, :rand.uniform(noNodes)]
            true -> [i-1,i+1, :rand.uniform(noNodes)]
          end
          pid = spawn(fn -> Gossip_Line.start_link(i,neighboursIndices,1) end)
    end
    converger(noNodes,"gossip")
  end

  def start_gossip(noNodes,noNodes_started) do
    if noNodes_started < 1 do
      first_node = :rand.uniform(noNodes)  # get any of the node from the list as the first node
      first_node_id = TopologyStarter.whereis(first_node) # get the ID for the seleted node
      if first_node_id != nil do
        send(first_node_id,{:msgproc,"Distributed OS project: 2"}) # adds the message to be gossiped
        start_gossip(noNodes,noNodes_started+1)
      else
        start_gossip(noNodes,noNodes_started)
      end
    end
  end

  def pushSumFull(noNodes) do
    for i <- 1..noNodes do
      spawn(fn -> PushSum_Full.start_link(i,noNodes-1,1) end)
    end
    converger(noNodes,"push-sum")
  end

  def pushSum3D(noNodes) do
    indices = round(:math.pow(noNodes,(1/3)))
    k=0
    for i <- 1..noNodes do
      k =
      if rem(i,indices*indices)==0 do
        k+1
      else
        k
      end
      neighboursIndices =
        cond do
          i == 1 -> [i+1,i+indices,i+indices*indices]
          i == indices -> [i-1,i+indices,i+indices*indices]
          i == indices*indices - indices + 1 -> [i+1,i-indices,i+indices*indices]
          i == indices*indices -> [i-1,i-indices,i+indices*indices]
          i < indices -> [i-1,i+1,i+indices,i+indices*indices]
          i > indices*indices - indices + 1 and i < indices*indices -> [i-1,i+1,i-indices,i+indices*indices]

          i == indices*indices*(indices-1) + 1 -> [i+1,i+indices,i-indices*indices]
          i == indices*indices*(indices-1) + indices -> [i-1,i+indices,i-indices*indices]
          i == indices*indices*indices - indices + 1 -> [i+1,i-indices,i-indices*indices]
          i == indices*indices*indices -> [i-1,i-indices,i-indices*indices]
          i < indices*indices*(indices-1) + indices -> [i-1,i+1,i+indices,i-indices*indices]
          i > indices*indices*indices - indices + 1 and i < indices*indices*indices -> [i-1,i+1,i-indices,i-indices*indices]

          i == k*indices*indices + 1 -> [i+1,i+indices,i+indices*indices,i-indices*indices]
          i == k*indices*indices + indices -> [i-1,i+indices,i+indices*indices,i-indices*indices]
          i == k*indices*indices + indices*indices - indices + 1 -> [i+1,i-indices,i+indices*indices,i-indices*indices]
          i == k*indices*indices + indices*indices -> [i-1,i-indices,i+indices*indices,i-indices*indices]
          i < k*indices*indices + indices -> [i-1,i+1,i+indices,i+indices*indices,i-indices*indices]
          i > k*indices*indices + indices*indices - indices + 1 and i < k*indices*indices -> [i-1,i+1,i-indices,i+indices*indices,i-indices*indices]

          rem(i-1,indices) == 0 and k==0 ->
          [i+1,i-indices,i+indices,i+indices*indices]

          rem(i-1,indices) == 0 and k== indices-1 ->
          [i+1,i-indices,i+indices,i-indices*indices]

          rem(i-1,indices) == 0 ->
          [i+1,i-indices,i+indices ,i+indices*indices,i-indices*indices]

          rem(i,indices) == 0 and k==0 ->
          [i-1,i-indices,i+indices,i+indices*indices]

          rem(i,indices) == 0 and k== indices-1 ->
          [i-1,i-indices,i+indices,i-indices*indices]

          rem(i,indices) == 0 ->
          [i-1,i-indices,i+indices,i+indices*indices,i-indices*indices]

          true -> [i-1,i+1,i-indices,i+indices,i+indices*indices,i-indices*indices]
        end
      pid = spawn(fn -> PushSum_Line_2D_3D.start_link(i,neighboursIndices,1) end)
    end
    converger(noNodes,"push-sum")
  end

  def pushSumRandom2D(noNodes) do  # here consider as neighbour nodes if the distance between either x or y coordinates is 0.1
    listx = 1..noNodes |> Enum.map(fn _ -> Enum.random(1..100000)/100000 end)
    listy =1..noNodes |> Enum.map(fn _ -> Enum.random(1..100000)/100000 end)
    for i <- 0..noNodes-1 do
      listm=Enum.with_index(listx)
      listn=Enum.with_index(listy)
      list_x =  Enum.filter_map(listm , fn({x,_}) -> abs(Enum.at(listx,i)-x)<= 0.1 and abs(Enum.at(listx,i)-x) != 0 end, fn {_,x} -> "#{x+1}" end)
      finalx = Enum.map(list_x,fn(x) -> String.to_integer(x,10) end)
      list_y =  Enum.filter_map(listn , fn({x,_}) -> abs(Enum.at(listy,i)-x)<= 0.1 and abs(Enum.at(listy,i)-x) != 0 end, fn {_,x} -> "#{x+1}" end)
      finaly = Enum.map(list_y,fn(x) -> String.to_integer(x,10) end)
      neighboursIndices = finalx ++ finaly
      pid = spawn(fn -> PushSum_Line_2D_3D.start_link(i,neighboursIndices,1) end)
      Process.monitor(pid)
    end
    IO.puts "Waiting for convergence"
    final_convergence = Task.async(fn -> converging(noNodes,0) end)
    :global.register_name(:msgproc,final_convergence.pid)
    :global.register_name(:unconverged,self())
    st_time = :os.system_time(:millisecond)
    start_pushsum(noNodes,0)
    Task.await(final_convergence, :infinity)
    IO.puts ""
    IO.puts ""
    IO.puts "Time utilized to converge: #{inspect :os.system_time(:millisecond)-st_time} milliseconds"
  end

  def pushSumTorus(noNodes) do
    indices = round(:math.sqrt(noNodes))
    for i <- 1..noNodes do
      neighboursIndices =
        cond do
          i == 1 -> [i+1,i+indices,indices,noNodes-indices+1]
          i == indices -> [i-1,i+indices,1,noNodes]
          i == noNodes - indices + 1 -> [i+1,i-indices,1,noNodes]
          i == noNodes -> [i-1,i-indices,noNodes-indices+1,indices]
          i < indices -> [i-1,i+1,i+indices,i+noNodes-indices]
          i > noNodes - indices + 1 and i < noNodes -> [i-1,i+1,i-indices,i-noNodes+indices]
          rem((i-1),indices) == 0 -> [i+1,i-indices,i+indices,i-1+indices]
          rem(i,indices) == 0 -> [i-1,i-indices,i+indices,i+1-indices]
          true -> [i-1,i+1,i-indices,i+indices]
        end
      pid = spawn(fn -> PushSum_Line_2D_3D.start_link(i,neighboursIndices,1) end)
      Process.monitor(pid)
    end
    converger(noNodes,"push-sum")
  end

  def pushSumLine(noNodes) do
    for i <- 1..noNodes do
      neighboursIndices =
        cond do
          i == 1 -> [i+1]
          i == noNodes -> [i-1]
          true -> [i-1,i+1]
        end
      spawn(fn -> PushSum_Line_2D_3D.start_link(i,neighboursIndices,1) end)
    end
    converger(noNodes,"push-sum")
  end

  def pushSumImpLine(noNodes) do
    for i <- 1..noNodes do
      neighboursIndices =
        cond do
          i == 1 -> [i+1, :rand.uniform(noNodes)]
          i == noNodes -> [i-1, :rand.uniform(noNodes)]
          true -> [i-1,i+1, :rand.uniform(noNodes)]
        end
      pid = spawn(fn -> PushSum_Line_2D_3D.start_link(i,neighboursIndices,1) end)
    end
    converger(noNodes,"push-sum")
  end

  def start_pushsum(noNodes,noNodes_started) do
    if noNodes_started < 1 do
      first_node = :rand.uniform(noNodes)
      first_node_id = TopologyStarter.whereis(first_node)
      if first_node_id != nil do
        send(first_node_id,{:mainsw,0,0})
        start_pushsum(noNodes,noNodes_started+1)
      else
        start_pushsum(noNodes,noNodes_started)
      end
    end
  end

  def converger(noNodes, algorithm) do
    IO.puts "Waiting for convergence"
    final_convergence = Task.async(fn -> converging(noNodes,0) end)
    :global.register_name(:msgproc,final_convergence.pid)
    :global.register_name(:unconverged,self())
    st_time = :os.system_time(:millisecond)
    if algorithm == "gossip" do
      start_gossip(noNodes,0)
    else
      start_pushsum(noNodes,0)
    end
    Task.await(final_convergence, :infinity)
    IO.puts ""
    IO.puts ""
    IO.puts "Time utilized to converge: #{inspect :os.system_time(:millisecond)-st_time} milliseconds"
  end

  def converging(noNodes,stopping_threshold) do
    if(noNodes > 0) do
      receive do
        {:converged,pid} -> IO.write "."
                            converging(noNodes-1,stopping_threshold)
      after
        5000 -> IO.puts "No convergence for #{noNodes}"
        send(:global.whereis_name(:unconverged),{:DOWN, :random, :process, :random, :cantconverge})
        converging(noNodes-1,stopping_threshold)
      end
    else
      nil
    end
  end

  @node_namein_register :node_name
  def whereis(node_id) do
      case Registry.lookup(@node_namein_register, node_id) do
      [{pid, _}] -> pid
      [] -> nil
      end
  end
end

defmodule CommonFuntions do
  require Logger

  @node_namein_register :node_name
  def via_tuple(node_id), do: {:via, Registry, {@node_namein_register, node_id}}

  def node(count,buzz,buzzerProcess)  do
    if(count < 10) do # we do the gossip until the message reaches 10 nodes
      receive do
        {:transferbuzz,buzz} -> node(count+1,buzz,buzzerProcess)
      end
    else
      send(:global.whereis_name(:msgproc),{:converged,self()})
      Task.shutdown(buzzerProcess,:brutal_kill) # shutdown when 10 tims reached
    end
  end

  def nodePS(count,s,w,oldsbyw,buzzerProcess)  do
    newsbyw = s/w
    change = abs(newsbyw - oldsbyw)
    count = if change > :math.pow(10,-10), do: 0, else: count + 1
    if count>=3 do
      send(:global.whereis_name(:msgproc),{:converged,self()})
      Task.shutdown(buzzerProcess,:brutal_kill)
      Process.exit(self(),:normal)
    else
      s=s/2
      w=w/2
      send(elem(buzzerProcess,1),{:updaterumor,s,w})
      receive do
          {:transferbuzz,incomings,incomingw} -> nodePS(count,incomings+s,incomingw+w,newsbyw,buzzerProcess)
      after
          100 -> nodePS(count,s,w,newsbyw,buzzerProcess)
      end
    end
  end

end

defmodule Gossip_Line do
  use GenServer
  require Logger

  def start_link(node_id,neighboursIndices,nodes_to_ping) when is_integer(node_id) do
    GenServer.start_link(__MODULE__, [node_id,neighboursIndices,nodes_to_ping], name: CommonFuntions.via_tuple(node_id))
  end

  def init([node_id,neighboursIndices,nodes_to_ping]) do
    receive do
      {_,buzz} -> buzzerProcess = Task.start fn -> start_process(neighboursIndices,buzz,nodes_to_ping) end
                   CommonFuntions.node(1,buzz,buzzerProcess)
    end
    {:ok, node_id}
  end

  def start_process(neighboursIndices,buzz,nodes_to_ping) do
    for _ <- 1..nodes_to_ping do
        index = :rand.uniform(length(neighboursIndices))-1
        neighbour_id =  TopologyStarter.whereis(Enum.at(neighboursIndices,index))
        if neighbour_id != nil do
            send(neighbour_id,{:transferbuzz,buzz})
        end
    end
    Process.sleep(100) # for time difference between starting 2 processes
    start_process(neighboursIndices,buzz,nodes_to_ping)
  end
end

defmodule Gossip_Full do
  use GenServer
  require Logger

  def start_link(node_id,neighboursCount,nodes_to_ping) when is_integer(node_id) do
    GenServer.start_link(__MODULE__, [node_id,neighboursCount,nodes_to_ping], name: CommonFuntions.via_tuple(node_id))
  end

  def init([node_id,neighboursCount,nodes_to_ping]) do
    receive do
      {_,buzz} -> buzzerProcess = Task.start fn -> start_process(node_id,neighboursCount,buzz,nodes_to_ping) end
                   CommonFuntions.node(1,buzz,buzzerProcess)
    end
    {:ok, node_id}
  end

  def start_process(node_id,neighboursCount,buzz,nodes_to_ping) do
    for _ <- 1..nodes_to_ping do
      seed = :rand.uniform(neighboursCount)
      neighbour_id = if seed < node_id do
        TopologyStarter.whereis(seed)
      else
        TopologyStarter.whereis(seed+1)
      end
      if neighbour_id != nil do
        send(neighbour_id,{:transferbuzz,buzz})
      end
    end
    Process.sleep(100) # for time difference between starting 2 processes
    start_process(node_id,neighboursCount,buzz,nodes_to_ping)
  end
end

defmodule Gossip_2D_3D_Torus do
  use GenServer
  require Logger

  def start_link(node_id,neighboursIndices,noNodes,nodes_to_ping) when is_integer(node_id) do
    GenServer.start_link(__MODULE__, [node_id,neighboursIndices,noNodes,nodes_to_ping], name: CommonFuntions.via_tuple(node_id))
  end

  def init([node_id,neighboursIndices,noNodes,nodes_to_ping]) do
    receive do
        {_,buzz} -> buzzerProcess = Task.start fn -> start_process(node_id,neighboursIndices,buzz,noNodes,nodes_to_ping) end
                     CommonFuntions.node(1,buzz,buzzerProcess)
    end
    {:ok, node_id}
  end

  def start_process(node_id,neighboursIndices,buzz,noNodes,nodes_to_ping) do
    for _ <- 1..nodes_to_ping do
      index = :rand.uniform(length(neighboursIndices)+1)-1
      neighbour_id =
        if(index == length(neighboursIndices)) do
          TopologyStarter.whereis(getrandomneighbour([node_id | neighboursIndices],noNodes))
        else
          TopologyStarter.whereis(Enum.at(neighboursIndices,index))
        end
      if neighbour_id != nil do
        send(neighbour_id,{:transferbuzz,buzz})
      end
    end
    Process.sleep(100) # for time difference between starting 2 processes
    start_process(node_id,neighboursIndices,buzz,noNodes,nodes_to_ping)
  end

  def getrandomneighbour(exceptList,noNodes) do
    randneigh = :rand.uniform(noNodes)
    if randneigh in exceptList do
      getrandomneighbour(exceptList,noNodes)
    else
      randneigh
    end
  end

end

defmodule PushSum_Line_2D_3D do
  use GenServer
  require Logger

  def start_link(node_id,neighboursIndices,nodes_to_ping) when is_integer(node_id) do
    GenServer.start_link(__MODULE__, [node_id,neighboursIndices,nodes_to_ping], name: CommonFuntions.via_tuple(node_id))
  end

  def init([node_id,neighboursIndices,nodes_to_ping]) do
    receive do
      {_,s,w} -> buzzerProcess = Task.start fn -> start_process(node_id,neighboursIndices,s+node_id,w+1,nodes_to_ping) end
                 CommonFuntions.nodePS(1,s+node_id,w+1,node_id,buzzerProcess)
    end
    {:ok, node_id}
  end

  def start_process(node_id,neighboursIndices,s,w,nodes_to_ping) do
    try do
        {s,w} = receive do
                    {:updaterumor,updateds,updatedw} -> {updateds,updatedw}
                end
        for _ <- 1..nodes_to_ping do
          index = :rand.uniform(length(neighboursIndices))-1
          neighbour_id =  TopologyStarter.whereis(Enum.at(neighboursIndices,index))
          if neighbour_id != nil do
            send(neighbour_id,{:transferbuzz,s,w})
          end
        end
        start_process(node_id,neighboursIndices,s,w,nodes_to_ping)
        rescue
            _ -> start_process(node_id,neighboursIndices,s,w,nodes_to_ping)
    end
  end
end

defmodule PushSum_Full do
  use GenServer
  require Logger

  def start_link(node_id,neighboursCount,nodes_to_ping) when is_integer(node_id) do
    GenServer.start_link(__MODULE__, [node_id,neighboursCount,nodes_to_ping], name: CommonFuntions.via_tuple(node_id))
  end

  def init([node_id,neighboursCount,nodes_to_ping]) do
    receive do
      {_,s,w} -> buzzerProcess = Task.start fn -> start_process(node_id,neighboursCount,s+node_id,w+1,nodes_to_ping) end
                 CommonFuntions.nodePS(1,s+node_id,w+1,node_id,buzzerProcess)
    end
    {:ok, node_id}
  end


  def start_process(node_id,neighboursCount,s,w,nodes_to_ping) do
    try do
      {s,w} = receive do
                  {:updaterumor,updateds,updatedw} -> {updateds,updatedw}
              end
      for _ <- 1..nodes_to_ping do
        seed = :rand.uniform(neighboursCount)
        neighbour_id = if seed < node_id, do: TopologyStarter.whereis(seed), else: TopologyStarter.whereis(seed+1)
        if neighbour_id != nil do
          send(neighbour_id,{:transferbuzz,s,w})
        end
      end
      start_process(node_id,neighboursCount,s,w,nodes_to_ping)
      rescue
          _ -> start_process(node_id,neighboursCount,s,w,nodes_to_ping)
    end
  end
end

defmodule MainServer do
  def main(args) do
    args |> parse_args
  end

  defp parse_args([]) do
    IO.puts "No arguments given. Enter parameters again"
  end

  defp parse_args(args) do
    {_, k, _} = OptionParser.parse(args,  strict: [limit: :integer])
      n = String.to_integer(Enum.at(k,0))
      topology = String.downcase(Enum.at(k,1))
      algorithm = String.downcase(Enum.at(k,2))
      noNodes = if String.contains?(topology,"2d") do
        sqroot = :math.sqrt(n)
        sqr = Float.ceil(sqroot,0)
        if (sqr - sqroot)>0 do
          get_next_square(n)
        else
          n
        end
      else
         n
      end
      Registry.start_link(keys: :unique, name: :node_name)
      case topology do
        "full" -> if algorithm == "gossip" do
          TopologyStarter.gossipFull(noNodes)
        else
          TopologyStarter.pushSumFull(noNodes)
        end

        "3d" -> if algorithm == "gossip" do
          TopologyStarter.gossip3D(noNodes)
        else
          TopologyStarter.pushSum3D(noNodes)
        end

        "random2d" -> if algorithm == "gossip" do
          TopologyStarter.gossipRandom2D(noNodes)
        else
          TopologyStarter.pushSumRandom2D(noNodes)
        end

        "torus" -> if algorithm == "gossip" do
          TopologyStarter.gossipTorus(noNodes)
        else
          TopologyStarter.pushSumTorus(noNodes)
        end

        "line" -> if algorithm == "gossip" do
          TopologyStarter.gossipLine(noNodes)
        else
          TopologyStarter.pushSumLine(noNodes)
        end

        "impline" -> if algorithm == "gossip" do
          TopologyStarter.gossipImpLine(noNodes)
        else
          TopologyStarter.pushSumImpLine(noNodes)
        end

        _ -> IO.puts "Give correct topology"
      end
    end
    def get_next_square(n) do
      sqroot = :math.sqrt(n)
      sqr = Float.ceil(sqroot,0)
      if (sqr - sqroot)>0 do
        get_next_square(n+1)
      else
        n
      end
    end
end
